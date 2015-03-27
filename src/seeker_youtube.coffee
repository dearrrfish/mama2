###
    Youtube
    @dearrrfish
###

#canPlayM3U8 = require './canPlayM3U8'
#queryString = require './queryString'
ajax = require './ajax'
#httpProxy = require './httpProxy'
log = require './log'

exports.match = ->
    /youtube\.com/.test(location.href) && !!window.google_video_doc_id

exports.getVideos = (callback) ->
    log('开始解析youtube视频地址')
    parseYoutube(window.google_video_doc_id.replace('yt_', ''), callback)


exports.decodeQueryString = decodeQueryString = (query) ->
    r = {}
    qs = query.split('&')
    for q in qs
        k = decodeURIComponent(q.split('=')[0])
        v = decodeURIComponent(q.split('=')[1] || '')
        r[k] = v
    r

exports.decodeYoutubeSourceMap = decodeYoutubeSourceMap = (raw) ->
    map = {}
    for src in raw.split(',')
        stream = decodeQueryString(src)
        type = stream.type.split(';')[0]
        quality = stream.quality.split(';')[0]
        url = "#{stream.url}&signature=#{stream.sig}"
        map["#{type} #{quality}"] =
            type: type
            quality: quality
            url: url
    map


exports.parseYoutube = parseYoutube = (_id, callback) ->
    ajax({
        url: "https://www.youtube.com/get_video_info?video_id=#{_id}"
        contentType: "text"
        callback: (video_info) ->
            if video_info == -1
                log('解析youtube视频地址失败', 2)
                return

            video = decodeQueryString(video_info)
            video.srcs = decodeYoutubeSourceMap(video.url_encoded_fmt_stream_map)

            video.getSource = (type, quality...) ->
                backup = exact = ''
                for k,src of @srcs
                    if src.type.match(type)
                        if src.quality.match(quality)
                            exact = src.url
                            return exact
                        else
                            backup = src.url
                backup

            source = [
                ['超清', video.getSource('video/mp4', 'hd720')],
                ['高清', video.getSource('video/mp4', 'medium')],
                ['标清', video.getSource('video/mp4', 'small')]
            ]

            log('解析youtube视频地址成功 ' + source.map((item) -> '<a href='+item[1]+'>'+item[0]+'</a>').join(' '), 2)
            callback(source)
    })


