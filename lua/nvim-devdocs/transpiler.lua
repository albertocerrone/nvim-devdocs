M = {}

local normalize_html = function(str)
  local subs = {
    ["&copy;"] = "©",
    ["&ndash;"] = "–",
    ["&lt;"] = "<",
    ["<a.*>(.*)</a>"] = "%1",
    ["<br>"] = "",
    ["\n *"] = " ",
  }

  for pattern, repl in pairs(subs) do
    str = string.gsub(str, pattern, repl)
  end

  return str
end

M.to_yaml = function(entry)
  local lines = {}

  for key, value in pairs(entry) do
    if key == "attribution" then value = normalize_html(value) end
    if key == "links" then value = vim.fn.json_encode(value) end
    table.insert(lines, key .. ": " .. value)
  end

  return lines
end

M.html_to_md = function(html)
  -- TODO: find a better way
  html = html:gsub("<p.->(.-)</p>", "%1\n")
  html = html:gsub("<p.->", "")

  html = html:gsub("<h1.->(.-)</h1>", "# %1\n")
  html = html:gsub("<h2.->(.-)</h2>", "## %1\n")
  html = html:gsub("<h3.->(.-)</h3>", "### %1\n")
  html = html:gsub("<h4.->(.-)</h4>", "#### %1\n")
  html = html:gsub("<h5.->(.-)</h5>", "##### %1\n")
  html = html:gsub("<h6.->(.-)</h6>", "###### %1\n")

  html = html:gsub("<ul>(.-)</ul>", function(list)
    list = list:gsub("<li>(.-)</li>", "- %1")
    return list
  end)
  html = html:gsub("<ol>(.-)</ol>", function(list)
    local counter = 1
    list = list:gsub("<li>(.-)</li>", function(item)
      counter = counter + 1
      return counter - 1 .. ". " .. item
    end)
    return list
  end)

  html = html:gsub('<a href="(.-)">(.-)</a>', "[%2](%1)")
  html = html:gsub("<a href='(.-)'>(.-)</a>", "[%2](%1)")
  html = html:gsub('<img%s+src="(.-)"%s+alt="(.-)"[^>]*>', "![%2](%1)")
  html = html:gsub("<img%s+src='(.-)'%s+alt='(.-)'[^>]*>", "![%2](%1)")

  html = html:gsub("<strong>(.-)</strong>", "**%1**")
  html = html:gsub("<em>(.-)</em>", "_%1_")
  html = html:gsub("<pre><code>(.-)</code></pre>", "```\n%1\n```")
  html = html:gsub("<blockquote>(.-)</blockquote>", "> %1\n")
  html = html:gsub("<sup>(.-)</sup>", "^%1^")

  html = html:gsub("<code>(.-)</code>", "`%1`")

  html = html:gsub("<br>", "\n")
  html = html:gsub("<hr>", "\n---\n")

  html = html:gsub("\n\n\n", "\n\n")
  html = html:gsub("&copy;", "©")
  html = html:gsub("&ndash;", "–")
  html = html:gsub("&lt;", "<")
  html = html:gsub("&gt;", "<")

  return html
end

return M
