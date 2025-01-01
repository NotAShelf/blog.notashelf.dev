--[[
  # Synopsis:
  Lua filter to add anchor links to all headings in a document, excluding the post title.

  # Usage:
   $ pandoc -s -L filters/anchor.lua  notes/cheatsheet.md -o output.html
--]]
function Header(el)
    if el.level ~= 1 then
        local id = el.content[1].text:match("^%s*(.-)%s*$"):lower():gsub("%s+", "-")

        el.attributes = el.attributes or {} -- Ensure that 'attributes' is initialized
        el.attributes.id = id

        local anchor = pandoc.RawInline('html',
            ' <a href="#' .. id .. '" style="margin-left: 8px; font-size: 0.9em">🔗</a>')

        table.insert(el.content, anchor)
    end

    return el
end
