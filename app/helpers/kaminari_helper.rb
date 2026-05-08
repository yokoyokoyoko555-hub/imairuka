module KaminariHelper
  def page_tag(page)
    if page.current?
      tag.li class: 'page-item active' do
        tag.span page, class: 'page-link'
      end
    else
      tag.li class: 'page-item' do
        link_to page, page.url, class: 'page-link', rel: page.rel
      end
    end
  end

  def first_page_tag
    tag.li class: 'page-item' do
      link_to url_for(page: 1), class: 'page-link', aria: { label: t('views.pagination.first') } do
        tag.span '&laquo;'.html_safe, aria: { hidden: true }
      end
    end
  end

  def prev_page_tag
    tag.li class: 'page-item' do
      link_to url_for(page: current_page - 1), class: 'page-link', rel: 'prev', aria: { label: t('views.pagination.previous') } do
        tag.span '&lsaquo;'.html_safe, aria: { hidden: true }
      end
    end
  end

  def next_page_tag
    tag.li class: 'page-item' do
      link_to url_for(page: current_page + 1), class: 'page-link', rel: 'next', aria: { label: t('views.pagination.next') } do
        tag.span '&rsaquo;'.html_safe, aria: { hidden: true }
      end
    end
  end

  def last_page_tag
    tag.li class: 'page-item' do
      link_to url_for(page: total_pages), class: 'page-link', aria: { label: t('views.pagination.last') } do
        tag.span '&raquo;'.html_safe, aria: { hidden: true }
      end
    end
  end

  def gap_tag
    tag.li class: 'page-item disabled' do
      tag.span '&hellip;'.html_safe, class: 'page-link'
    end
  end
end 