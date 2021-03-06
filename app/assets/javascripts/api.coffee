gr_$ = jQuery.noConflict()

parseQuery = (query) ->
  Params = new Object
  if !query
    return Params
  
  Pairs = query.split(/[;&]/)
  i = 0
  while i < Pairs.length
    KeyVal = Pairs[i].split('=')
    if !KeyVal or KeyVal.length != 2
      i++
      continue
    key = unescape(KeyVal[0])
    val = unescape(KeyVal[1])
    val = val.replace(/\+/g, ' ')
    Params[key] = val
    i++
  Params

qs = gr_$("script[src*='getreview.ru']").attr("src").replace(/^[^\?]+\??/,'')
params = parseQuery(qs)

h = document.getElementsByTagName("head")[0]
css = document.createElement("link")
css.rel = "stylesheet"
css.type = "text/css"
css.href = "http://getreview.ru/widget/widget.css"
h.appendChild(css)

GetReview = {}
GetReview.WidgetUID = params.gr_widget_code

gr_$ ->
  GetReview.API.initialize()

  try
    initEvent = new CustomEvent("gr:widget:ready")
    document.dispatchEvent initEvent

    document.addEventListener "gr:widget:open", (e) ->
      GetReview.API.showPanel()

    document.addEventListener "gr:widget:initialize", (e) ->
      GetReview.API.initialize()
      
  catch error
    # Обрабатывать не нужно
    

GetReview.API = 

  initialize: ->
    return false if GetReview.API.detectMobile(navigator.userAgent || navigator.vendor || window.opera)

    GetReview.API.getWidget (data) ->
      GetReview.Data = data

      return false unless data.show_widget

      grWidgetButton = document.createElement("div")
      gr_$(grWidgetButton).addClass("gr-widget").addClass("gr-widget-button")
      gr_$(grWidgetButton).addClass GetReview.Data.color_schema
      gr_$(grWidgetButton).html "<div class = 'gr-widget gr-button-reviews-count'>#{GetReview.Data.reviews_count}</div> #{GetReview.Data.reviews_count_text}"

      grOverlay = document.createElement("div")
      gr_$(grOverlay).addClass("gr-widget").addClass("gr-overlay")

      grCloseOverlayButton = document.createElement("div")
      gr_$(grCloseOverlayButton).addClass("gr-widget").addClass("gr-close-overlay-icon")

      grPanel = document.createElement("div")
      gr_$(grPanel).addClass("gr-widget").addClass("gr-widget-panel")

      grPanelContainer = document.createElement("div")
      gr_$(grPanelContainer).addClass("gr-widget").addClass "gr-widget-panel-container"

      gr_$("body").append grOverlay
      gr_$("body").append grCloseOverlayButton
      gr_$("body").append grPanel
      gr_$("body").append grWidgetButton

      gr_$(".gr-widget-panel").append grPanelContainer

      if GetReview.Data.reviews_count == 0
        gr_$(".gr-widget-panel").addClass("gr-widget-panel-empty")
        gr_$(".gr-widget-panel").addClass("gr-#{GetReview.Data.color_schema}-bg")
        gr_$(".gr-widget-panel-container").append(GetReview.API.renderEmpty(GetReview.Data))
      else
        gr_$(".gr-widget-panel-container").append(GetReview.API.renderReviewsTop(GetReview.Data))
        gr_$(".gr-widget-panel-container").append(GetReview.API.renderReviewsHeader(GetReview.Data))
        gr_$(".gr-widget-panel-container").perfectScrollbar()

      gr_$(grWidgetButton).on "click", -> 
        GetReview.API.showPanel()
      gr_$(grCloseOverlayButton).on "click", -> GetReview.API.hidePanel()
      gr_$(grOverlay).on "click", -> GetReview.API.hidePanel()

  showPanel: ->
    GetReview.API.showReviews() if gr_$(".gr-reviews").size() == 0

    overlay = gr_$(".gr-overlay")
    overlay.css "opacity", 0
    overlay.show()
    overlay.animate({opacity: "0.8"}, 300)

    closeIcon = gr_$(".gr-close-overlay-icon")
    closeIcon.css "top", "-40px"
    closeIcon.css "opacity", "0"
    closeIcon.show()
    closeIcon.animate {top: "30px", opacity: 1}, 300

    panel = gr_$(".gr-widget-panel")
    panel.css("left", "-520px")
    panel.css "opacity", 0
    panel.show()
    gr_$(".gr-widget-panel-container").scrollTop(0)
    panel.animate {"left": "0px", "opacity": 1}, 300 

    gr_$(document).trigger "gr:widget:panel:opened"


  hidePanel: ->
    overlay = gr_$(".gr-overlay")
    overlay.animate {opacity: "0"}, 300, -> overlay.hide()

    closeIcon = gr_$(".gr-close-overlay-icon")
    closeIcon.animate {top: "-40px", opacity: 0}, 300, -> closeIcon.hide()

    panel = gr_$(".gr-widget-panel")
    panel.animate {"left": "-520px", "opacity": 0}, 300, -> panel.hide()


  showReviews: ->
    GetReview.API.showLoading()
    reviewsRoot = document.createElement("div")
    gr_$(reviewsRoot).addClass("gr-widget").addClass("gr-reviews")

    GetReview.API.getReviews (reviews) ->
      gr_$(reviewsRoot).append(GetReview.API.renderReview(reviewData)) for reviewData in reviews
      GetReview.API.hideLoading()
      gr_$(".gr-widget-panel-container").append reviewsRoot

  showLoading: ->
    gr_$(".gr-widget-panel-container").append GetReview.API.renderLoading()

  hideLoading: ->
    gr_$(".gr-widget-panel-container").find(".gr-reviews-loading").remove()
      



  renderEmpty: (data) ->
    """
      <div class = "gr-widget gr-widget-panel-empty-box">
        <div class = "gr-widget gr-widget-panel-empty-title">
          Увы, никто еще не написал ни одного отзыва,
          но вы можете быть первым!
        </div>
        <a href = "#{data.review_board_url}"  class = "gr-widget gr-button" target = "_blank">Написать первый отзыв</a>
      </div>
    """


  renderReviewsTop: (data) ->
    """
      <div class = "gr-widget gr-widget-top gr-#{data.color_schema}-bg">
        <a href = "#{data.review_board_url}" class = "gr-widget gr-button" target = "_blank"> Написать свой отзыв </a>
      </div>
    """

  renderReviewsHeader: (data) ->
    """
      <div class ="gr-widget gr-reviews-header">
        <div class = "gr-widget gr-reviews-total-rate">
          <div class = "gr-widget gr-reviews-total-rate-stars #{GetReview.API.getStarsClassByRate(data.average_rate_rounded)}"></div>
        </div>
        <div class = "gr-widget gr-reviews-total-count">
          #{data.reviews_count} #{data.reviews_count_text} о компании</div>
        <div class = "gr-widget gr-reviews-company-name">«#{data.company_name}»</div>
      </div>
    """

  renderLoading: ->
    """
      <div class = "gr-reviews-loading">
        <li></li>
        <li></li>
        <li></li>
      </div>
    """

  renderReview: (data) ->
    """
      <div class = "gr-widget gr-review">
        <div class = "gr-widget gr-review-header">
          <div class = "gr-widget gr-review-author-avatar">
            <img src = "#{data.avatar}" class = "gr-widget">
          </div>

          <div class = "gr-widget gr-review-author-details">
            <div class = "gr-widget gr-review-author-name">#{data.username}</div>
            <div class = "gr-widget gr-review-author-url">
              <a href = "#{data.user_url}" target = "_blank" class = "gr-widget">#{data.user_url}</a>
            </div>

          </div>

          <div class = "gr-widget gr-review-right">
            <div class ="gr-widget gr-review-rate-stars #{GetReview.API.getStarsClassByRate(data.rate)}"></div>
            <div class = "gr-widget gr-review-date">#{data.date}</div>
          </div>

        </div>

        <div class = "gr-widget gr-review-body">
          #{GetReview.API.decorateText(data.content)}
        </div>
      </div>
    """

  getWidget: (cb) ->
    gr_$.get(
      "http://getreview.ru/api/widget/#{GetReview.WidgetUID}.json",
      (data) ->
        if data.status = "success"
          cb(data)
    )

  getReviews: (cb) ->
    gr_$.get(
      "http://getreview.ru/api/reviews/#{GetReview.WidgetUID}.json",
      (data) ->
        if data.status == "success"
          cb(data.reviews)
    )

  getStarsClassByRate: (rate) ->
    switch rate
      when 1 then return "one-star"
      when 2 then return "two-stars"
      when 3 then return "three-stars"
      when 4 then return "four-stars"
      when 5 then return "five-stars"

  decorateText: (str) ->
    lines = str.replace(/[\r\n]+/g, '\n').split("\n")
    "<p class = 'gr-widget'>" + lines.join("</p><p class = 'gr-widget'>") + "</p>"


  detectMobile: (a) ->
    if (/(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino/i.test(a) || /1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.test(a.substr(0, 4)))
      return true
    else
      return false


