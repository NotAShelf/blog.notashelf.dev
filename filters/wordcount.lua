--[[
  # Synopsis:
  Lua filter for calculating the word count (with & without spaces) and the estimated time
  to read any given article based on the calculated word count. Assumes a very generous 265wpm
  for reading speed, based on Medium's own calculation method:
    <https://medium.com/blogging-guide/how-is-medium-article-read-time-calculated-924420338a85>

  The filter is adapted from:
   <https://github.com/pandoc/lua-filters/blob/master/wordcount/wordcount.lua>

  # Usage:
   $ pandoc -s -L filters/wordcount.lua -M wordcount=process notes/cheatsheet.md -o output.html
--]]

local words = 0
local characters = 0
local characters_and_spaces = 0
local process_anyway = false
local reading_speed = 265    -- words per minute
local image_count = 0
local seconds_per_image = 12 -- 12 seconds per image
local reading_time_position = 2

-- Safely get the utf8 length, handling invalid sequences
local function safe_utf8_len(text)
    local success, len = pcall(function() return utf8.len(text) end)
    if success then
        return len
    else
        return string.len(text)
    end
end

local wordcount = {
    Str = function(el)
        -- Count actual words by splitting on whitespace/punctuation
        local _, count = el.text:gsub("%S+", "")
        words = words + count

        local len = safe_utf8_len(el.text)
        characters = characters + len
        characters_and_spaces = characters_and_spaces + len
    end,

    Space = function(el)
        characters_and_spaces = characters_and_spaces + 1
    end,

    Code = function(el)
        -- Use a single pattern to count non-space sequences
        local _, n = el.text:gsub("%S+", "")
        words = words + n
        local text_nospace = el.text:gsub("%s", "")
        characters = characters + safe_utf8_len(text_nospace)
        characters_and_spaces = characters_and_spaces + safe_utf8_len(el.text)
    end,

    CodeBlock = function(el)
        -- Use a single pattern to count non-space sequences
        local _, n = el.text:gsub("%S+", "")
        words = words + n
        local text_nospace = el.text:gsub("%s", "")
        characters = characters + safe_utf8_len(text_nospace)
        characters_and_spaces = characters_and_spaces + safe_utf8_len(el.text)
    end,

    Image = function(el)
        image_count = image_count + 1
    end
}

function Meta(meta)
    if meta.wordcount and (meta.wordcount == "process-anyway" or meta.wordcount == "process" or meta.wordcount == "convert") then
        process_anyway = true
    end

    -- Reading speed configuration
    if meta.reading_speed then
        reading_speed = tonumber(meta.reading_speed) or reading_speed
    end

    -- Position configuration
    if meta.reading_time_position then
        reading_time_position = tonumber(meta.reading_time_position) or 2
    end

    -- Image time configuration
    if meta.seconds_per_image then
        seconds_per_image = tonumber(meta.seconds_per_image) or seconds_per_image
    end
end

function Pandoc(el)
    -- Skip metadata, just count body:
    pandoc.walk_block(pandoc.Div(el.blocks), wordcount)

    -- Calculate image time in minutes
    local image_time = math.ceil((image_count * seconds_per_image) / 60)

    -- Calculate total reading time
    local reading_time = math.ceil(words / reading_speed) + image_time

    -- Format the display text
    local display_text
    if reading_time <= 1 then
        display_text = "1 minute read"
    else
        display_text = string.format("%d minute read", reading_time)
    end

    -- Create the reading time element
    local para = pandoc.Para({
        pandoc.Str(display_text)
    })

    -- Wrap the paragraph in a Div and assign the class 'reading-time'
    local div = pandoc.Div(para, { class = "reading-time" })

    -- Insert the Div block into the block list at position 2
    table.insert(el.blocks, reading_time_position, div)

    print("\27[36m[INFO]\27[0m " ..
        words ..
        " words, " ..
        characters ..
        " characters, " ..
        characters_and_spaces ..
        " characters (including spaces), " ..
        image_count .. " images, " .. reading_time .. " minute(s) estimated reading time")

    if not process_anyway then
        os.exit(0)
    end

    return el
end
