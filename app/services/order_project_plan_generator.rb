require "erb"
require "json"
require "net/http"
require "uri"

class OrderProjectPlanGenerator
  def initialize(order)
    @order = order
    @company = order.company
  end

  def generate
    tasks = ai_tasks.presence || fallback_tasks
    tasks.each_with_index.map do |task, index|
      {
        title: task.fetch("title"),
        description: task["description"],
        start_date: parse_date(task["start_date"]) || Date.current + index.weeks,
        due_date: parse_date(task["due_date"]) || Date.current + index.weeks + 4.days,
        priority: task["priority"].presence_in(OrderProjectTask.priorities.keys) || "normal",
        position: index + 1
      }
    end
  end

  private

  attr_reader :order, :company

  def ai_tasks
    api_key = company.decrypted_ai_api_key
    return [] if api_key.blank?

    case company.ai_provider
    when "openai"
      openai_tasks(api_key)
    when "claude"
      claude_tasks(api_key)
    when "gemini"
      gemini_tasks(api_key)
    when "copilot"
      Rails.logger.warn("Project plan AI fallback: Copilot direct API is not enabled")
      []
    else
      []
    end
  rescue => e
    Rails.logger.warn("Project plan AI fallback: #{e.class} #{e.message}")
    []
  end

  def openai_tasks(api_key)
    uri = URI("https://api.openai.com/v1/responses")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"
    request.body = {
      model: company.ai_model_or_default,
      instructions: system_instruction,
      input: prompt
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
    return [] unless response.is_a?(Net::HTTPSuccess)

    body = JSON.parse(response.body)
    text = body.fetch("output", []).flat_map { |item| item.fetch("content", []) }.find { |content| content["type"] == "output_text" }&.fetch("text", nil)
    parse_json_tasks(text)
  end

  def claude_tasks(api_key)
    uri = URI("https://api.anthropic.com/v1/messages")
    request = Net::HTTP::Post.new(uri)
    request["x-api-key"] = api_key
    request["anthropic-version"] = "2023-06-01"
    request["Content-Type"] = "application/json"
    request.body = {
      model: company.ai_model_or_default,
      max_tokens: 1_500,
      system: system_instruction,
      messages: [
        { role: "user", content: prompt }
      ]
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
    return [] unless response.is_a?(Net::HTTPSuccess)

    body = JSON.parse(response.body)
    text = body.fetch("content", []).find { |content| content["type"] == "text" }&.fetch("text", nil)
    parse_json_tasks(text)
  end

  def gemini_tasks(api_key)
    model = ERB::Util.url_encode(company.ai_model_or_default)
    key = ERB::Util.url_encode(api_key)
    uri = URI("https://generativelanguage.googleapis.com/v1beta/models/#{model}:generateContent?key=#{key}")
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = {
      system_instruction: {
        parts: [{ text: system_instruction }]
      },
      contents: [
        {
          role: "user",
          parts: [{ text: prompt }]
        }
      ],
      generation_config: {
        temperature: 0.2
      }
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
    return [] unless response.is_a?(Net::HTTPSuccess)

    body = JSON.parse(response.body)
    text = body.fetch("candidates", []).first&.dig("content", "parts")&.find { |part| part["text"].present? }&.fetch("text", nil)
    parse_json_tasks(text)
  end

  def parse_json_tasks(text)
    return [] if text.blank?

    cleaned = text.to_s.strip.sub(/\A```(?:json)?/i, "").sub(/```\z/, "").strip
    parsed = JSON.parse(cleaned)
    parsed.is_a?(Hash) ? parsed.fetch("tasks", []) : parsed
  rescue JSON::ParserError
    []
  end

  def fallback_tasks
    base = Date.current
    [
      ["要件整理", "案件概要をもとに目的、成果物、前提条件を整理します。", base, base + 3.days, "high"],
      ["実行計画作成", "作業範囲、担当、スケジュール、確認ポイントを定義します。", base + 4.days, base + 7.days, "high"],
      ["制作・実装", "主要な作業を進め、必要な成果物を作成します。", base + 8.days, base + 21.days, "normal"],
      ["確認・修正", "関係者レビューを行い、指摘事項を反映します。", base + 22.days, base + 27.days, "normal"],
      ["納品・完了処理", "最終確認、納品、請求に必要な情報を整理します。", base + 28.days, base + 31.days, "normal"]
    ].map do |title, description, start_date, due_date, priority|
      { "title" => title, "description" => description, "start_date" => start_date.to_s, "due_date" => due_date.to_s, "priority" => priority }
    end
  end

  def prompt
    <<~TEXT
      次の案件概要から、ガントチャート用の大きな工程を5〜8件作成してください。
      タスク管理表には工程配下の細かい作業を後から追加するため、ここでは工程レベルにしてください。
      JSON配列、または {"tasks":[...]} のJSONだけを返してください。
      各工程は title, description, start_date, due_date, priority(low/normal/high/urgent) を持たせてください。

      案件名: #{order.project_name.presence || order.display_order_number}
      顧客名: #{order.customer&.name}
      案件概要:
      #{order.project_summary.presence || order.notes}
      今日: #{Date.current}
    TEXT
  end

  def system_instruction
    "あなたは日本語のプロジェクトマネージャーです。JSONだけを返してください。"
  end

  def parse_date(value)
    Date.parse(value.to_s)
  rescue ArgumentError
    nil
  end
end
