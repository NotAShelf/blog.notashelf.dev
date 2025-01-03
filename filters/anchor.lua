--[[
  # Synopsis:
  Lua filter to add anchor links to all headings in a document, excluding the post title.

  # Usage:
   $ pandoc -s -L filters/anchor.lua  notes/cheatsheet.md -o output.html
--]]
function Header(el)
    if el.level ~= 1 then
        -- Sanitize special characters to avoid weird cutoffs
        local id = pandoc.utils.stringify(el.content)
            :gsub("^%s*(.-)%s*$", "%1")
            :lower()
            :gsub("%s+", "-")
            :gsub("[^%w%-]", "")

        el.attributes = el.attributes or {}
        el.attributes.id = id

        local anchor = pandoc.RawInline('html',
            ' <a href="#' .. id .. '" class="anchor-link">🔗</a>')
        table.insert(el.content, anchor)
    end
    return el
end
