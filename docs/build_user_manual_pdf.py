from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.cidfonts import UnicodeCIDFont
from reportlab.platypus import (
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


OUT = Path(__file__).with_name("imairuka_user_manual.pdf")

pdfmetrics.registerFont(UnicodeCIDFont("HeiseiKakuGo-W5"))
FONT = "HeiseiKakuGo-W5"

styles = getSampleStyleSheet()
styles.add(ParagraphStyle("CoverBrand", fontName=FONT, fontSize=14, leading=18, textColor=colors.HexColor("#2563eb")))
styles.add(ParagraphStyle("CoverTitle", fontName=FONT, fontSize=28, leading=36, textColor=colors.HexColor("#0f172a")))
styles.add(ParagraphStyle("CoverMeta", fontName=FONT, fontSize=11, leading=18, textColor=colors.HexColor("#475569")))
styles.add(ParagraphStyle("H2", fontName=FONT, fontSize=17, leading=23, textColor=colors.HexColor("#0f172a"), spaceBefore=12, spaceAfter=8))
styles.add(ParagraphStyle("H3", fontName=FONT, fontSize=13, leading=18, textColor=colors.HexColor("#0f172a"), spaceBefore=8, spaceAfter=5))
styles.add(ParagraphStyle("BodyJP", fontName=FONT, fontSize=10, leading=15, textColor=colors.HexColor("#172033")))
styles.add(ParagraphStyle("SmallJP", fontName=FONT, fontSize=8, leading=12, textColor=colors.HexColor("#64748b")))


def p(text, style="BodyJP"):
    return Paragraph(text.replace("\n", "<br/>"), styles[style])


def bullets(items):
    story = []
    for item in items:
        story.append(p(f"・{item}"))
    return story


def numbered(items):
    story = []
    for i, item in enumerate(items, 1):
        story.append(p(f"{i}. {item}"))
    return story


def table(rows, widths=None):
    data = [[p(str(cell)) for cell in row] for row in rows]
    t = Table(data, colWidths=widths, repeatRows=1)
    t.setStyle(
        TableStyle(
            [
                ("FONTNAME", (0, 0), (-1, -1), FONT),
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#f1f5f9")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.HexColor("#0f172a")),
                ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#d8dee9")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                ("TOPPADDING", (0, 0), (-1, -1), 6),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
            ]
        )
    )
    return t


def note(text, color="#eff6ff", border="#2563eb"):
    t = Table([[p(text)]], colWidths=[170 * mm])
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor(color)),
                ("BOX", (0, 0), (-1, -1), 0.5, colors.HexColor(border)),
                ("LEFTPADDING", (0, 0), (-1, -1), 9),
                ("RIGHTPADDING", (0, 0), (-1, -1), 9),
                ("TOPPADDING", (0, 0), (-1, -1), 8),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
            ]
        )
    )
    return t


def footer(canvas, doc):
    canvas.saveState()
    canvas.setFont(FONT, 8)
    canvas.setFillColor(colors.HexColor("#64748b"))
    canvas.drawRightString(A4[0] - 14 * mm, 9 * mm, f"Imairuka 利用者マニュアル / {doc.page}")
    canvas.restoreState()


story = []

story += [
    Spacer(1, 55 * mm),
    p("Imairuka", "CoverBrand"),
    Spacer(1, 6 * mm),
    p("イマイルカ<br/>利用者マニュアル", "CoverTitle"),
    Spacer(1, 12 * mm),
    p("ASP / SaaS版 現時点版<br/>対象: 利用企業の管理者・担当者", "CoverMeta"),
    Spacer(1, 8 * mm),
    p("この資料は、利用者がイマイルカを使い始め、案件・文書・決済・ユーザーを管理するための基本操作をまとめたものです。", "SmallJP"),
    PageBreak(),
]

story += [
    p("1. イマイルカでできること", "H2"),
    p("イマイルカは、受注・案件管理を中心に、顧客、商品、見積書、納品書、請求書、領収書、決済履歴、プロジェクト進行をまとめて管理する業務管理システムです。"),
    table(
        [
            ["領域", "主な機能"],
            ["案件管理", "案件登録、案件名・案件概要、請求情報、処理履歴、プロジェクト管理"],
            ["プロジェクト管理", "ガントチャート、AIによる下書き、タスク管理、課題管理、アサイン管理"],
            ["文書管理", "見積書、納品書、請求書、領収書の作成・一覧・印刷"],
            ["決済管理", "Stripe連携、決済開始、Webhookによる決済履歴保存、入金状態確認"],
            ["設定", "会社情報、ステータス、Stripe連携、AI APIキー設定"],
            ["ユーザー管理", "複数アカウント招待、権限変更、停止、プランに応じた招待可能数表示"],
        ],
        [38 * mm, 132 * mm],
    ),
    p("2. 利用開始の流れ", "H2"),
    table(
        [["利用申込", "→", "運営承認", "→", "招待URL受領", "→", "アカウント作成", "→", "ログイン"]],
        [28 * mm, 7 * mm, 28 * mm, 7 * mm, 33 * mm, 7 * mm, 35 * mm, 7 * mm, 18 * mm],
    ),
    *numbered(
        [
            "利用者は申込フォームから会社情報を送信します。",
            "運営側が申込内容を確認し、承認します。",
            "承認後、初期管理者用の招待URLが発行されます。",
            "招待URLから氏名・メールアドレス・パスワードを設定します。",
            "ログイン後、会社情報やStripe連携などの初期設定を行います。",
        ]
    ),
    p("申込URL: https://imairuka-order-793fd07d208c.herokuapp.com/signup"),
    p("ログインURL: https://imairuka-order-793fd07d208c.herokuapp.com/login"),
    PageBreak(),
]

story += [
    p("3. 基本画面の見方", "H2"),
    p("ログイン後は、左メニューから各機能へ移動します。上部メニューには主要な管理機能が表示されます。"),
    table(
        [
            ["メニュー", "用途"],
            ["ダッシュボード", "全体状況の確認に使います。"],
            ["案件管理", "受注・案件の登録、確認、プロジェクト管理に使います。"],
            ["請求管理", "請求対象の案件、支払期限、支払方法、入金状態を確認します。"],
            ["決済履歴", "Stripe決済や入金記録を確認します。"],
            ["文書管理", "見積書、納品書、請求書、領収書を管理します。"],
            ["顧客管理・商品管理", "顧客情報、商品・サービス情報を登録します。"],
            ["設定", "会社情報、ステータス、Stripe、AI APIキーを設定します。"],
        ],
        [42 * mm, 128 * mm],
    ),
    p("4. 案件管理", "H2"),
    p("案件を登録する", "H3"),
    *numbered(
        [
            "左メニューの「案件管理」を開きます。",
            "新規作成ボタンから案件を作成します。",
            "顧客、案件名、案件概要、商品、金額、支払方法、支払期限などを入力します。",
            "保存すると案件一覧に表示されます。",
        ]
    ),
    note("案件番号はシステムが自動で発行します。形式は例として「ORD-202605-0001」のような実運用向けの番号です。"),
    p("案件詳細で確認できること", "H3"),
    *bullets(["顧客名、案件名、案件概要", "金額、支払方法、支払期限、ステータス", "処理履歴", "プロジェクト管理への移動"]),
    PageBreak(),
]

story += [
    p("5. プロジェクト管理", "H2"),
    p("案件詳細の「プロジェクト管理」から、案件の進行を管理できます。"),
    table(
        [
            ["機能", "説明"],
            ["ガントチャート", "案件全体の大まかな工程を確認します。"],
            ["AI下書き作成", "案件概要をもとに、工程・タスクの下書きを作成します。"],
            ["タスク管理", "ガントの工程より細かい作業単位を管理します。"],
            ["課題管理", "進行上の問題、対応状況、担当者を管理します。"],
            ["アサイン管理", "案件に関わる担当者を登録します。"],
        ],
        [42 * mm, 128 * mm],
    ),
    note("AI機能を使うには、設定画面で利用企業自身のAI APIキーを登録する必要があります。", "#fffbeb", "#f59e0b"),
    p("6. 顧客管理・商品管理", "H2"),
    *bullets(
        [
            "顧客管理では、会社名、担当者、住所、連絡先などを管理します。",
            "商品管理では、商品名、単価、税率などを管理します。",
            "案件・見積・請求書などで、登録済み情報を利用できます。",
        ]
    ),
    p("7. 文書管理", "H2"),
    p("文書管理では、見積書、納品書、請求書、領収書を作成・確認できます。各一覧には案件名も表示されるため、どの案件に紐づく文書か確認しやすくなっています。"),
    table(
        [
            ["文書", "主な用途"],
            ["見積書", "受注前の金額・条件提示に使います。"],
            ["納品書", "納品内容の記録に使います。"],
            ["請求書", "顧客への請求内容を管理します。"],
            ["領収書", "入金後の領収記録として使います。"],
        ],
        [42 * mm, 128 * mm],
    ),
    PageBreak(),
]

story += [
    p("8. 請求管理・決済管理", "H2"),
    p("請求一覧では、案件ごとの支払期限、支払方法、入金状況を確認できます。案件名列も表示されます。"),
    p("Stripe連携", "H3"),
    *numbered(
        [
            "設定画面を開きます。",
            "Stripe連携を選択します。",
            "「Stripeと連携」から、利用企業自身のStripeアカウントを接続します。",
            "決済受付が有効になると、案件からStripe決済を開始できます。",
        ]
    ),
    note("イマイルカはStripe Connect方式を利用します。利用企業ごとにStripeアカウントを連携し、自社の顧客から決済を受け付ける形です。"),
    p("決済履歴", "H3"),
    p("決済履歴では、案件番号、顧客名、決済金額、支払方法、支払期限、入金日、決済状態を確認できます。Stripe Session IDは通常業務では不要なため、一覧画面には表示していません。内部的にはWebhook照合や障害調査のため保持しています。"),
    p("9. ユーザー管理と権限", "H2"),
    p("管理者権限を持つユーザーは、同じ会社のユーザーを招待できます。招待可能なユーザー数は契約プランに応じて制限されます。"),
    table(
        [
            ["権限", "概要"],
            ["オーナー", "会社設定、ユーザー管理、主要機能を管理できます。"],
            ["管理者", "業務管理とユーザー管理を行えます。"],
            ["経理", "請求・決済関連の操作に向いた権限です。"],
            ["一般", "案件や文書など通常業務を行うユーザーです。"],
            ["閲覧のみ", "確認中心のユーザーです。"],
        ],
        [42 * mm, 128 * mm],
    ),
    note("追加アカウントは契約状態とプランに応じて解放されます。未課金または上限到達時は招待できません。", "#fffbeb", "#f59e0b"),
    PageBreak(),
]

story += [
    p("10. 設定", "H2"),
    *bullets(
        [
            "会社情報: 自社名、住所、連絡先、登録番号などを管理します。",
            "ステータス設定: 案件の進行ステータスを管理します。",
            "Stripe連携: 決済受付のためのStripe Connectを設定します。",
            "AI設定: AIによるガント・タスク下書きに使うAPIキーを設定します。",
        ]
    ),
    p("11. よくある運用の流れ", "H2"),
    *numbered(
        [
            "顧客と商品を登録します。",
            "案件を作成し、案件名と案件概要を入力します。",
            "必要に応じてAIでプロジェクト計画を下書きします。",
            "タスク、課題、担当者を整理します。",
            "見積書を作成します。",
            "受注後、納品書・請求書を作成します。",
            "Stripe決済または入金情報を確認します。",
            "入金後、領収書を発行します。",
        ]
    ),
    p("12. 困ったとき", "H2"),
    table(
        [
            ["状況", "確認ポイント"],
            ["ログインできない", "メールアドレス、パスワード、招待URLの有効期限を確認してください。"],
            ["ユーザーを招待できない", "契約状態、プラン上限、既存の招待中メールアドレスを確認してください。"],
            ["Stripe決済が使えない", "Stripe連携状態、決済受付の有効化、本人確認の状況を確認してください。"],
            ["AI下書きが使えない", "設定画面でAI APIキーが登録されているか確認してください。"],
            ["文書の案件が分かりにくい", "各文書一覧の「案件名」列を確認してください。"],
        ],
        [48 * mm, 122 * mm],
    ),
    Spacer(1, 8 * mm),
    p("最終更新: 2026年5月13日 / Imairuka ASP版 利用者マニュアル", "SmallJP"),
]

doc = SimpleDocTemplate(
    str(OUT),
    pagesize=A4,
    rightMargin=14 * mm,
    leftMargin=14 * mm,
    topMargin=16 * mm,
    bottomMargin=16 * mm,
    title="イマイルカ 利用者マニュアル",
)
doc.build(story, onFirstPage=footer, onLaterPages=footer)
print(OUT)
