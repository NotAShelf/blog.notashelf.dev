--[[
  # Synopsis:
  Lua filter for calculatin gthe word count (with & without spaces) and the estimated time
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
local reading_speed = 265 -- words per minute

-- Safely get the utf8 length, handling invalid sequences
local function safe_utf8_len(text)
    local success, len = pcall(function() return utf8.len(text) end)
    if success then
        return len
    else
        return 0
    end
end

local wordcount = {
    Str = function(el)
        -- Count words only if there is a non-punctuation character
        if el.text:match("%P") then
            words = words + 1
        end
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
    end
}

function Meta(meta)
    if meta.wordcount and (meta.wordcount == "process-anyway" or meta.wordcount == "process" or meta.wordcount == "convert") then
        process_anyway = true
    end
end

function Pandoc(el)
    -- Skip metadata, just count body:
    pandoc.walk_block(pandoc.Div(el.blocks), wordcount)
    local reading_time = math.ceil(words / reading_speed)
    local para = pandoc.Para({
        pandoc.Str(string.format("%d minute read", reading_time))
    })

    -- Wrap the paragraph in a Div and assign the class 'reading-time'
    local div = pandoc.Div(para, { class = "reading-time" })

    -- Insert the Div block into the block list at position 2
    table.insert(el.blocks, 2, div)

    print(words .. " words")
    print(characters .. " characters")
    print(characters_and_spaces .. " characters (including spaces)")
    print(reading_time .. " minute(s) estimated reading time")

    if not process_anyway then
        os.exit(0)
    end

    return el
end
