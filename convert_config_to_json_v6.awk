#!/usr/bin/awk -f
# convert_config_to_json_v6.awk
# Reads a Config0_XXXXX file and outputs JSON with:
#   - "DateTime": formatted as dd-MMM-yyyy HH:MM:SS.fff (3‑digit milliseconds)
#   - "values":   array of numeric measurements
# Handles Windows (CRLF) and Unix (LF) line endings, stray whitespace,
# and any non‑numeric characters that may appear in the data section.

BEGIN {
    # Record separator handles both LF and CRLF
    RS = "\r?\n"
    # Month name mapping (1 = Jan, 2 = Feb, ...)
    monthNames[1] = "Jan"; monthNames[2] = "Feb"; monthNames[3] = "Mar"; monthNames[4] = "Apr";
    monthNames[5] = "May"; monthNames[6] = "Jun"; monthNames[7] = "Jul"; monthNames[8] = "Aug";
    monthNames[9] = "Sep"; monthNames[10] = "Oct"; monthNames[11] = "Nov"; monthNames[12] = "Dec";

    datetime = ""
    in_values = 0
    value_count = 0
}

/^Date[ \t]/ {
    # Capture the date (e.g., 2025/07/25)
    split($0, parts, /[ \t]+/)
    raw_date = parts[2]               # "2025/07/25"
    split(raw_date, dparts, "/")
    year  = dparts[1]
    month = dparts[2] + 0              # numeric month for lookup
    day   = dparts[3]
}

/^Time[ \t]/ {
    # Capture the time (e.g., 18:43:05.3223881721496582031)
    split($0, parts, /[ \t]+/)
    raw_time = parts[2]               # "18:43:05.3223881721496582031"
    split(raw_time, tparts, ".")
    time_sec = tparts[1]              # "18:43:05"
    frac = tparts[2]
    milli = substr(frac, 1, 3)        # first three digits of fractional part
    datetime = sprintf("%02d-%s-%04d %s.%s", day, monthNames[month], year, time_sec, milli)
}

/^X_Value[ \t]/ {
    # Start of the numeric data block
    in_values = 1
    next
}

/^[ \t]*$/ {
    # Blank line – stop collecting values if we were in the data block
    if (in_values) { in_values = 0 }
    next
}

{
    if (in_values) {
        # Remove any characters that are not part of a number.
        gsub(/[^\-0-9.eE+]/, " ", $0)

        # Split the cleaned line into potential numeric tokens.
        token_cnt = split($0, tokens, " ")
        for (i = 1; i <= token_cnt; i++) {
            if (tokens[i] != "" && tokens[i] ~ /^[+-]?[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)?$/) {
                values[++value_count] = tokens[i]
            }
        }
    }
}

END {
    print "{"
    printf "  \"DateTime\": \"%s\",\n", datetime
    printf "  \"values\": ["
    for (i = 1; i <= value_count; i++) {
        printf "%s%s", values[i], (i < value_count ? ", " : "")
    }
    print "]"
    print "}"
}
