require 'html_processor'

class ContentItemDecorator < Draper::Decorator
  decorates_association :categories, with: CategoryDecorator

  delegate :title, :type, :slug, :description, :id, :accepts_feedback?

  def initialize(object, options = {})
    super
    self.processors = html_processors
  end

  def alternate_options
    object.alternates.each_with_object({}) do |alternate, hash|
      hash[alternate.hreflang] = alternate.url
    end
  end

  def footer_alternate_options
    Hash[alternate_options.map { |key, value| [key.scan(/\w+/).first, value] }].except(I18n.locale.to_s)
  end

  def canonical_url
    resource_path = "#{object.class.to_s.demodulize.underscore.chomp('_preview')}_url"
    h.send(resource_path, object.id)
  end

  def content
    processed_body.html_safe
  end

  def social_share_image
    @social_share_image ||= h.parent_category.try(:large_image) || h.image_url('MAS-logo_social-sharing.png')
  end

  private

  attr_accessor :processors

  def processed_body
    body = object.body

    processors.each do |processor, xpaths|
      body = processor.new(body).process(*xpaths)
    end

    body
  end

  def html_processors
    [
      [HTMLProcessor::NodeRemover, [HTMLProcessor::INTRO_IMG,
                                    HTMLProcessor::ACTION_EMAIL,
                                    HTMLProcessor::ACTION_FORM,
                                    HTMLProcessor::COLLAPSIBLE_SPAN]],

      [HTMLProcessor::VideoWrapper, [HTMLProcessor::VIDEO_IFRAME]],
      [HTMLProcessor::TableWrapper, [HTMLProcessor::DATATABLE_DEFAULT]],
      [HTMLProcessor::HeadingAttributes, [HTMLProcessor::HEADINGS]]
    ]
  end
end
