# frozen_string_literal: true

# Checks that assessments only test taught objectives, every objective is tested, and keys and links are complete.
class CoverageCheck
  ROOT = __dir__
  OBJECTIVE = /\*\*\[([A-Z]\d+\.\d+)\]\*\*/
  QUESTION = /^#+ ([QF]\d+) \((\d+(?:\.\d+)?) pts?\)/
  COVERS = /^_Covers: (.+)_$/
  TOTAL = /\((?:closed-book, )?(\d+) points, pass at (\d+)\)/
  FINAL = 5

  Question = Data.define(:id, :points, :covers)

  def initialize
    @errors = []
    @objectives = read_objectives
  end

  def run
    Dir[File.join(ROOT, 'phase-*', 'assessment.md')].each { |path| check_assessment(path[/phase-(\d)/, 1].to_i, path) }
    check_assessment(FINAL, File.join(ROOT, 'final', 'assessment.md'))
    check_links
    puts "#{@objectives.size} objectives defined"
    return puts('OK: every check passed') if @errors.empty?

    @errors.each { |message| warn "ERROR: #{message}" }
    exit 1
  end

  private

  def phase_of(id) = id[/\d/].to_i

  def read_objectives
    ids = Dir[File.join(ROOT, 'phase-*', 'lessons.md')].flat_map { |path| File.read(path).scan(OBJECTIVE).flatten }
    ids.tally.each { |id, count| error("objective #{id} is defined #{count} times") if count > 1 }
    ids.uniq
  end

  def check_assessment(phase, path)
    @path = path.delete_prefix("#{ROOT}/")
    text = File.read(path)
    questions = parse_questions(text)
    check_coverage(phase, questions, text)
    check_points(text, questions.to_h { |question| [question.id, question.points] })
    check_key(phase, questions.map(&:id))
    summarize(questions)
  end

  def check_coverage(phase, questions, text)
    questions.each { |question| check_ids(phase, question.id, question.covers) }
    check_ids(phase, 'Part B', part_b_ids(text))
    check_completeness(phase, questions.flat_map(&:covers))
  end

  def part_b_ids(text) = text[/^## Part B.*?(?=^## Part C|\z)/m].to_s.scan(/\b[ROGW]\d\.\d+\b/).uniq

  def summarize(questions)
    objectives = questions.flat_map(&:covers).uniq.size
    puts "#{@path}: #{questions.size} questions, #{questions.sum(&:points).round} points, #{objectives} objectives"
  end

  def parse_questions(text)
    text.split(/(?=^#+ [QF]\d+ \()/).filter_map do |chunk|
      next unless (heading = chunk.match(QUESTION))

      covers = chunk[COVERS, 1].to_s.split(/,\s*/)
      error("#{heading[1]} has no Covers line") if covers.empty?
      Question.new(id: heading[1], points: heading[2].to_f, covers:)
    end
  end

  def check_ids(phase, where, ids)
    ids.each do |id|
      error("#{where} covers untaught #{id}") unless @objectives.include?(id)
      error("#{where} covers #{id} from a later phase") if phase_of(id) > phase
    end
  end

  def check_completeness(phase, covered)
    phases = phase == FINAL ? (1..4) : [phase]
    required = phase == FINAL ? 0.5 : 1.0
    phases.each do |taught|
      own = @objectives.select { |id| phase_of(id) == taught }
      next if (own & covered).size >= own.size * required

      error("Part A misses too much of phase #{taught}; untested: #{(own - covered).join(', ')}")
    end
  end

  def check_points(text, points)
    part_a = text[/^## Part A.*?(?=^## Part B)/m].to_s
    check_total(part_a, points, 0.8)
    part_a.split(/^(?=### Section )/).grep(/\A### Section [ROGW]/).each { |section| check_total(section, points, 0.7) }
  end

  def check_total(block, points, share)
    title = block.lines.first.strip
    total, pass = title.match(TOTAL).to_a.drop(1).map(&:to_i)
    return error("no points total in: #{title}") unless total

    actual = block.scan(QUESTION).sum { |id, _| points[id] }
    error("#{title}: questions add up to #{actual}") unless actual == total
    check_pass_mark(title, (total * share).ceil, pass)
  end

  def check_pass_mark(title, expected, pass)
    error("#{title}: pass mark should be #{expected}") unless pass == expected
  end

  def check_key(phase, ids)
    key = File.join(ROOT, 'answer-keys', phase == FINAL ? 'final.md' : "phase-#{phase}.md")
    answered = File.read(key).scan(/^#+ ([QF]\d+)$/).flatten
    (ids - answered).each { |id| error("answer key has no answer for #{id}") }
    (answered - ids).each { |id| error("answer key answers #{id}, which is not a question") }
  end

  def check_links
    Dir[File.join(ROOT, '**', '*.md')].each do |path|
      @path = path.delete_prefix("#{ROOT}/")
      File.read(path).scan(/\]\(([^)#:]+)(?:#[^)]*)?\)/).flatten.each do |link|
        error("links to missing #{link}") unless File.exist?(File.expand_path(link, File.dirname(path)))
      end
    end
  end

  def error(message) = @errors << "#{@path}: #{message}"
end

CoverageCheck.new.run
