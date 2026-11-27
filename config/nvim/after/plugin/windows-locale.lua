-- Windows can inherit C.UTF-8 from the shell but fall back to plain C in its CRT.
if vim.fn.has("win32") == 1 and vim.v.ctype == "C" then
    vim.cmd("language ctype .UTF-8")
end
