function time_series_intraday_extended(symbol::String, interval::String="60min", slice::String="year1month1"; client = GLOBAL[], parser = "default")
    @argcheck in(interval, ["1min", "5min", "15min", "30min", "60min"])
    sliceMatch = match(r"year(?<year>\d+)month(?<month>\d+)", slice)
    @argcheck !Compat.isnothing(sliceMatch)
    @argcheck parse(Int, sliceMatch["year"]) > 0
    @argcheck parse(Int, sliceMatch["year"]) < 3
    @argcheck parse(Int, sliceMatch["month"]) > 0
    @argcheck parse(Int, sliceMatch["month"]) < 13
    uri = _form_uri_head(client, "TIME_SERIES_INTRADAY_EXTENDED") * "&symbol=$symbol&interval=$interval&slice=$slice" * _form_uri_tail(client, nothing, nothing)
    data = retry(_get_request, delays=Base.ExponentialBackOff(n=3, first_delay=5, max_delay=1000))(uri)
    p = _parser(parser, "csv")
    return p(data)
end

function time_series_intraday(symbol::String, interval::String="1min"; client = GLOBAL[], outputsize::String="compact", datatype::String="json", parser = "default")
    @argcheck in(interval, ["1min", "5min", "15min", "30min", "60min"])
    @argcheck in(outputsize, ["compact", "full"])
    @argcheck in(datatype, ["json", "csv"])
    uri = _form_uri_head(client, "TIME_SERIES_INTRADAY") * "&symbol=$symbol&interval=$interval" * _form_uri_tail(client, outputsize, datatype)
    data = retry(_get_request, delays=Base.ExponentialBackOff(n=3, first_delay=5, max_delay=1000))(uri)
    p = _parser(parser, datatype)
    return p(data)
end

for func in (:daily, :daily_adjusted, :weekly, :weekly_adjusted, :monthly, :monthly_adjusted)
    x = "time_series_$(func)"
    fname = Symbol(x)
    @eval begin
        function ($fname)(symbol::String; client = GLOBAL[], outputsize::String="compact", datatype::String="json", parser = "default")
            @argcheck in(outputsize, ["compact", "full"])
            @argcheck in(datatype, ["json", "csv"])
            uri = _form_uri_head(client, uppercase($x)) * "&symbol=$symbol" * _form_uri_tail(client, outputsize, datatype)
            data = retry(_get_request, delays=Base.ExponentialBackOff(n=3, first_delay=5, max_delay=1000))(uri)
            p = _parser(parser, datatype)
            return p(data)
        end

        export $fname
    end
end
