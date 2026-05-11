from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.pdfbase.cidfonts import UnicodeCIDFont
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfgen import canvas
from reportlab.platypus import Paragraph


OUT = Path(__file__).with_name("imairuka_asp_overview_map.pdf")
PAGE_W, PAGE_H = landscape(A4)

pdfmetrics.registerFont(UnicodeCIDFont("HeiseiKakuGo-W5"))
FONT = "HeiseiKakuGo-W5"


TITLE = ParagraphStyle(
    "Title",
    fontName=FONT,
    fontSize=22,
    leading=28,
    textColor=colors.HexColor("#0f172a"),
    alignment=TA_LEFT,
)
SUB = ParagraphStyle(
    "Sub",
    fontName=FONT,
    fontSize=10,
    leading=14,
    textColor=colors.HexColor("#475569"),
)
BODY = ParagraphStyle(
    "Body",
    fontName=FONT,
    fontSize=9,
    leading=12,
    textColor=colors.HexColor("#0f172a"),
    alignment=TA_CENTER,
)
SMALL = ParagraphStyle(
    "Small",
    fontName=FONT,
    fontSize=7.5,
    leading=10,
    textColor=colors.HexColor("#334155"),
    alignment=TA_CENTER,
)


def para(c, text, x, y, w, h, style=BODY):
    p = Paragraph(text.replace("\n", "<br/>"), style)
    p.wrapOn(c, w, h)
    p.drawOn(c, x, y + h - p.height)


def box(c, x, y, w, h, text, fill="#ffffff", stroke="#cbd5e1", style=BODY, radius=5):
    c.setFillColor(colors.HexColor(fill))
    c.setStrokeColor(colors.HexColor(stroke))
    c.roundRect(x, y, w, h, radius, fill=1, stroke=1)
    para(c, text, x + 5, y + 4, w - 10, h - 8, style)


def arrow(c, x1, y1, x2, y2, color="#64748b"):
    c.setStrokeColor(colors.HexColor(color))
    c.setFillColor(colors.HexColor(color))
    c.setLineWidth(1.2)
    c.line(x1, y1, x2, y2)
    dx = 1 if x2 >= x1 else -1
    c.line(x2, y2, x2 - 4 * dx, y2 + 3)
    c.line(x2, y2, x2 - 4 * dx, y2 - 3)


def header(c, title, subtitle=None):
    c.setFillColor(colors.HexColor("#f8fafc"))
    c.rect(0, PAGE_H - 22 * mm, PAGE_W, 22 * mm, fill=1, stroke=0)
    para(c, title, 16 * mm, PAGE_H - 17 * mm, 180 * mm, 12 * mm, TITLE)
    if subtitle:
        para(c, subtitle, 205 * mm, PAGE_H - 14 * mm, 75 * mm, 8 * mm, SUB)
    c.setStrokeColor(colors.HexColor("#e2e8f0"))
    c.line(0, PAGE_H - 22 * mm, PAGE_W, PAGE_H - 22 * mm)


def footer(c, page):
    c.setFillColor(colors.HexColor("#64748b"))
    c.setFont(FONT, 8)
    c.drawRightString(PAGE_W - 12 * mm, 8 * mm, f"Imairuka ASP overview / {page}")


def page_overview(c):
    header(c, "Imairuka ASP 全体マップ", "契約、利用企業、業務、決済のつながり")
    footer(c, 1)

    center_x = 118 * mm
    y0 = PAGE_H - 55 * mm
    box(c, center_x - 28 * mm, y0, 56 * mm, 18 * mm, "Imairuka SaaS\n運営側", "#dbeafe", "#2563eb")

    nodes = [
        ("契約管理\n契約企業 / プラン / 状態", 18 * mm, 118 * mm, "#eff6ff"),
        ("利用企業\n案件 / 文書 / 決済", 93 * mm, 118 * mm, "#ecfdf5"),
        ("SaaS課金\n月額契約 / ユーザー上限", 168 * mm, 118 * mm, "#fff7ed"),
        ("Stripe Connect\n利用企業の決済受付", 243 * mm, 118 * mm, "#f5f3ff"),
    ]
    for text, x, y, fill in nodes:
        box(c, x, y, 58 * mm, 20 * mm, text, fill)
        arrow(c, center_x, y0, x + 29 * mm, y + 20 * mm)

    subnodes = [
        ("新規契約追加\n初期オーナー作成", 18 * mm, 87 * mm),
        ("契約状態\nactive / suspended", 18 * mm, 62 * mm),
        ("ユーザー管理\n招待 / 権限 / 停止", 88 * mm, 87 * mm),
        ("業務管理\n案件 / 顧客 / 商品", 88 * mm, 62 * mm),
        ("文書管理\n見積 / 納品 / 請求 / 領収", 88 * mm, 37 * mm),
        ("プラン制御\nstarter / standard / pro", 163 * mm, 87 * mm),
        ("招待制御\n未課金・上限到達で停止", 163 * mm, 62 * mm),
        ("決済履歴\nWebhook保存", 238 * mm, 87 * mm),
        ("支払い導線\nCheckout / 入金確認", 238 * mm, 62 * mm),
    ]
    for text, x, y in subnodes:
        box(c, x, y, 60 * mm, 17 * mm, text, "#ffffff", "#d1d5db", SMALL)


def page_contract(c):
    header(c, "契約から利用開始まで", "運営者が契約を追加し、利用企業が使い始める流れ")
    footer(c, 2)
    xs = [16, 61, 106, 151, 196, 241]
    labels = [
        "運営者が\n契約企業を追加",
        "会社情報\n登録",
        "初期オーナー\n作成",
        "契約状態と\nプラン設定",
        "月額契約\nactive",
        "利用開始\nユーザー招待",
    ]
    y = 118 * mm
    for i, (x, label) in enumerate(zip(xs, labels)):
        box(c, x * mm, y, 36 * mm, 24 * mm, label, "#eff6ff" if i < 4 else "#ecfdf5")
        if i < len(xs) - 1:
            arrow(c, (x + 36) * mm, y + 12 * mm, xs[i + 1] * mm, y + 12 * mm)

    box(c, 54 * mm, 70 * mm, 72 * mm, 24 * mm, "契約が active ではない場合\nアカウント追加は未解放", "#fef3c7", "#f59e0b")
    box(c, 168 * mm, 70 * mm, 72 * mm, 24 * mm, "active の場合\nプラン上限内で招待可能", "#dcfce7", "#16a34a")
    arrow(c, 214 * mm, 118 * mm, 204 * mm, 94 * mm)
    arrow(c, 214 * mm, 118 * mm, 90 * mm, 94 * mm)

    box(c, 22 * mm, 35 * mm, 236 * mm, 18 * mm, "現在の実装: active契約のみ招待可能。使用枠は「有効ユーザー数 + 未承諾招待数」で計算。", "#f8fafc", "#cbd5e1")


def page_invitation(c):
    header(c, "複数アカウント招待と課金制御", "招待UI、ユーザー上限、権限変更/停止の関係")
    footer(c, 3)
    flow = [
        ("ユーザーを招待", 22, 126, "#dbeafe"),
        ("契約 active?", 72, 126, "#f8fafc"),
        ("上限に空きあり?", 122, 126, "#f8fafc"),
        ("招待URL発行", 172, 126, "#dcfce7"),
        ("相手が参加", 222, 126, "#dcfce7"),
    ]
    for i, (text, x, y, fill) in enumerate(flow):
        box(c, x * mm, y * mm, 38 * mm, 22 * mm, text, fill)
        if i < len(flow) - 1:
            arrow(c, (x + 38) * mm, (y + 11) * mm, flow[i + 1][1] * mm, (y + 11) * mm)

    box(c, 72 * mm, 78 * mm, 38 * mm, 22 * mm, "No\n招待不可", "#fee2e2", "#ef4444")
    box(c, 122 * mm, 78 * mm, 38 * mm, 22 * mm, "No\nプラン変更/追加課金", "#fee2e2", "#ef4444")
    arrow(c, 91 * mm, 126 * mm, 91 * mm, 100 * mm, "#ef4444")
    arrow(c, 141 * mm, 126 * mm, 141 * mm, 100 * mm, "#ef4444")

    box(c, 24 * mm, 38 * mm, 52 * mm, 22 * mm, "招待UI\nコピー / 再発行 / 取消", "#ffffff")
    box(c, 86 * mm, 38 * mm, 52 * mm, 22 * mm, "既存ユーザー\n名前 / 権限変更", "#ffffff")
    box(c, 148 * mm, 38 * mm, 52 * mm, 22 * mm, "停止/再開\n自分自身は操作不可", "#ffffff")
    box(c, 210 * mm, 38 * mm, 52 * mm, 22 * mm, "ロール\nowner / admin / accounting\nmember / viewer", "#ffffff")


def page_stripe(c):
    header(c, "Stripeまわりの役割分担", "SaaS課金と利用企業の決済受付を分離")
    footer(c, 4)
    box(c, 24 * mm, 125 * mm, 56 * mm, 24 * mm, "運営側 Stripe\nSaaS月額課金", "#fff7ed", "#f97316")
    box(c, 118 * mm, 125 * mm, 56 * mm, 24 * mm, "Imairuka SaaS\n契約/権限/業務", "#dbeafe", "#2563eb")
    box(c, 212 * mm, 125 * mm, 56 * mm, 24 * mm, "利用企業 Stripe\nConnect連携", "#f5f3ff", "#7c3aed")
    arrow(c, 80 * mm, 137 * mm, 118 * mm, 137 * mm)
    arrow(c, 174 * mm, 137 * mm, 212 * mm, 137 * mm)

    box(c, 24 * mm, 85 * mm, 56 * mm, 22 * mm, "月額契約\nactive / past_due / canceled", "#ffffff")
    box(c, 24 * mm, 55 * mm, 56 * mm, 22 * mm, "プラン別\nユーザー上限", "#ffffff")
    box(c, 118 * mm, 85 * mm, 56 * mm, 22 * mm, "案件・請求から\n決済URL作成", "#ffffff")
    box(c, 118 * mm, 55 * mm, 56 * mm, 22 * mm, "Webhookで\n決済履歴保存", "#ffffff")
    box(c, 212 * mm, 85 * mm, 56 * mm, 22 * mm, "利用企業が\n自分のStripeへ連携", "#ffffff")
    box(c, 212 * mm, 55 * mm, 56 * mm, 22 * mm, "売上・入金は\n利用企業側へ", "#ffffff")


def page_roles(c):
    header(c, "権限ロールの整理", "運営者と利用企業ユーザーの役割")
    footer(c, 5)
    rows = [
        ("platform_admin", "運営管理者", "契約管理、全企業確認、初期設定"),
        ("owner", "オーナー", "自社管理、ユーザー招待、全業務操作"),
        ("admin", "管理者", "自社ユーザー管理、全業務操作"),
        ("accounting", "経理", "請求、決済、入金確認を中心に操作"),
        ("member", "一般", "案件、顧客、商品、文書の通常操作"),
        ("viewer", "閲覧のみ", "参照中心。更新制限は今後全画面へ展開"),
    ]
    x0, y0 = 22 * mm, 137 * mm
    widths = [46 * mm, 46 * mm, 170 * mm]
    headers = ["ロール", "表示名", "想定権限"]
    c.setFillColor(colors.HexColor("#1d4ed8"))
    c.rect(x0, y0, sum(widths), 12 * mm, fill=1, stroke=0)
    c.setFillColor(colors.white)
    c.setFont(FONT, 9)
    x = x0
    for text, w in zip(headers, widths):
        c.drawString(x + 4 * mm, y0 + 4 * mm, text)
        x += w
    y = y0 - 13 * mm
    for i, row in enumerate(rows):
        fill = "#ffffff" if i % 2 == 0 else "#f8fafc"
        c.setFillColor(colors.HexColor(fill))
        c.setStrokeColor(colors.HexColor("#e2e8f0"))
        c.rect(x0, y, sum(widths), 13 * mm, fill=1, stroke=1)
        x = x0
        c.setFillColor(colors.HexColor("#0f172a"))
        c.setFont(FONT, 8.5)
        for text, w in zip(row, widths):
            c.drawString(x + 4 * mm, y + 4.5 * mm, text)
            x += w
        y -= 13 * mm

    box(c, 22 * mm, 28 * mm, 262 * mm, 18 * mm, "次の改善候補: 契約管理画面からプラン/契約状態を変更、Stripe Subscriptionと同期、viewerの全画面読み取り専用制御。", "#f8fafc", "#cbd5e1")


def main():
    c = canvas.Canvas(str(OUT), pagesize=landscape(A4))
    for page in [page_overview, page_contract, page_invitation, page_stripe, page_roles]:
        page(c)
        c.showPage()
    c.save()
    print(OUT)


if __name__ == "__main__":
    main()
