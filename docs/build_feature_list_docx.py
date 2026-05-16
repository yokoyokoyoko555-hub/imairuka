# -*- coding: utf-8 -*-
from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor


OUT = r"C:\imairuka\imairuka_share_20260507\docs\Imairuka_feature_list_20260516.docx"


def set_font(run, size=10.5, bold=False, color=None):
    run.font.name = "Yu Gothic"
    run._element.rPr.rFonts.set(qn("w:eastAsia"), "Yu Gothic")
    run.font.size = Pt(size)
    run.font.bold = bold
    if color:
        run.font.color.rgb = RGBColor(*color)


def add_paragraph(doc, text, size=10.5, bold=False, color=None, space_after=6):
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(space_after)
    r = p.add_run(text)
    set_font(r, size=size, bold=bold, color=color)
    return p


def shade_cell(cell, fill):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:fill"), fill)
    tc_pr.append(shd)


def set_cell_text(cell, text, bold=False, fill=None):
    cell.text = ""
    p = cell.paragraphs[0]
    p.paragraph_format.space_after = Pt(0)
    r = p.add_run(text)
    set_font(r, size=9.5, bold=bold)
    cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
    if fill:
        shade_cell(cell, fill)


def add_table(doc, title, headers, rows, widths):
    add_paragraph(doc, title, size=14, bold=True, color=(0, 102, 204), space_after=8)
    table = doc.add_table(rows=1, cols=len(headers))
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.style = "Table Grid"
    for i, header in enumerate(headers):
        cell = table.rows[0].cells[i]
        set_cell_text(cell, header, bold=True, fill="EAF2FF")
        cell.width = Cm(widths[i])
    for row in rows:
        cells = table.add_row().cells
        for i, value in enumerate(row):
            set_cell_text(cells[i], value)
            cells[i].width = Cm(widths[i])
    doc.add_paragraph()


doc = Document()
section = doc.sections[0]
section.top_margin = Cm(1.6)
section.bottom_margin = Cm(1.6)
section.left_margin = Cm(1.8)
section.right_margin = Cm(1.8)

styles = doc.styles
styles["Normal"].font.name = "Yu Gothic"
styles["Normal"]._element.rPr.rFonts.set(qn("w:eastAsia"), "Yu Gothic")
styles["Normal"].font.size = Pt(10.5)

title = doc.add_paragraph()
title.alignment = WD_ALIGN_PARAGRAPH.CENTER
run = title.add_run("Imairuka 機能一覧")
set_font(run, size=24, bold=True, color=(0, 86, 179))

subtitle = doc.add_paragraph()
subtitle.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = subtitle.add_run("ASP型ローンチ前確認版 / 2026年05月16日")
set_font(r, size=11, color=(90, 90, 90))

add_paragraph(
    doc,
    "本資料は、現時点の Imairuka 案件管理システムで利用できる主要機能と、ASP型としての運用に必要な管理機能を整理したものです。インストール型は1社専用版として後続対応し、ASP型の完了後にまとめて反映します。",
    size=10.5,
    space_after=12,
)

add_table(
    doc,
    "1. 利用者向け 基本機能",
    ["カテゴリ", "機能", "概要"],
    [
        ["ダッシュボード", "利用状況の確認", "案件、文書、決済などの利用状況を確認します。"],
        ["案件一覧", "案件検索・一覧表示", "案件番号、顧客名、案件名、ステータス、タスク数、課題数、アサイン状況を一覧で確認します。"],
        ["案件詳細", "基本情報の確認", "顧客名、案件名、案件概要、ステータスなどを確認します。基本情報は折りたたみ可能です。"],
        ["プロジェクト管理", "ガント・タスク・課題・アサイン管理", "各案件に紐づく工程、詳細タスク、課題、担当者を管理します。"],
        ["AI下書き", "工程案の作成", "案件概要からAIで大まかなガントチャート案を作成します。会社ごとのAI APIキーを利用します。"],
    ],
    [3.2, 4.4, 10.2],
)

add_table(
    doc,
    "2. 文書・決済機能",
    ["カテゴリ", "機能", "概要"],
    [
        ["見積書", "作成・編集・プレビュー", "案件名を含めて見積書を作成し、PDFプレビューできます。"],
        ["納品書", "作成・管理", "案件に紐づく納品書を作成・管理します。"],
        ["請求書", "作成・管理", "案件に紐づく請求書を作成・管理します。"],
        ["領収書", "作成・管理", "入金後の領収書を作成・管理します。"],
        ["決済履歴", "Stripe Webhook保存", "Stripe決済成功イベントを受け取り、専用の決済履歴として保存・検索します。"],
        ["請求管理", "決済カテゴリ配下に配置", "請求関連の管理導線を決済管理カテゴリにまとめています。"],
    ],
    [3.2, 4.4, 10.2],
)

add_table(
    doc,
    "3. アカウント・権限・契約",
    ["カテゴリ", "機能", "概要"],
    [
        ["複数アカウント", "ユーザー招待", "契約に応じて利用可能なユーザー数を表示し、招待できます。基本契約は1名まで、追加アカウントは別途課金想定です。"],
        ["権限", "管理者・編集者・閲覧者", "ユーザーごとに権限を付与できます。閲覧者は編集・削除・追加操作が画面上でも非表示になります。"],
        ["利用申込", "契約候補の自動作成", "利用者申込フォームから運営側の契約管理に契約候補を自動作成します。"],
        ["運営承認", "契約開始", "運営側が契約候補を確認し、承認後に利用開始できる流れです。"],
        ["契約管理", "運営側専用", "運営管理画面は契約管理に集中し、利用者向けの文書作成機能とは分離しています。"],
    ],
    [3.2, 4.4, 10.2],
)

add_table(
    doc,
    "4. 運営管理・外部連携",
    ["カテゴリ", "機能", "概要"],
    [
        ["Stripe", "Connect連携", "利用者は自社のStripeアカウントを連携して決済を利用できます。運営側はStripe Connect設定が必要です。"],
        ["Stripe", "本番・テスト切替", "本番キーへの切替、Connect審査完了、Webhook本番設定が本番運用の前提です。"],
        ["AI設定", "OpenAI / Claude / Gemini", "会社ごとに利用するAIプロバイダーとAPIキーを設定します。Copilotは対象外です。"],
        ["マルチテナント", "会社単位のデータ分離", "ASP型では会社ごとに案件・文書・決済・ユーザー情報を分離します。"],
        ["セキュリティ", "閲覧者の書き込み制限", "閲覧権限ユーザーはサーバー側でも書き込み処理を拒否します。"],
    ],
    [3.2, 4.4, 10.2],
)

add_table(
    doc,
    "5. 残確認・後続タスク",
    ["優先度", "項目", "内容"],
    [
        ["高", "Stripe本番審査", "Connect審査完了後、本番キーとWebhookを最終確認します。"],
        ["高", "利用申込フロー", "申込、契約候補作成、運営承認、利用開始までの画面遷移を確認します。"],
        ["中", "契約・課金設計", "基本1名、追加アカウント課金の表示と運用ルールを詰めます。"],
        ["中", "操作説明資料", "画面キャプチャを追加した利用者向けマニュアルを整備します。"],
        ["後", "インストール型", "ASP型完了後、1社専用のインストール版へまとめてアップデートします。"],
    ],
    [2.4, 5.2, 10.2],
)

add_paragraph(
    doc,
    "備考: 本資料は機能整理用の一覧です。正式な販売資料では、画面キャプチャ、料金、サポート範囲、利用開始までの流れを追加します。",
    size=9.5,
    color=(90, 90, 90),
)

doc.save(OUT)
print(OUT)
