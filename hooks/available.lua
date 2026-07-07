--- 返回 MoonBit 所有可用版本
--- 数据来源: GitHub Releases API (moonbitlang/moonbit-compiler)
--- @param ctx table 上下文（args 为用户参数）
--- @return table[] 可用版本列表
function PLUGIN:Available(ctx)
    local http = require("http")
    local json = require("json")
    local util = require("util")

    local all_versions = {}
    local page = 1
    local per_page = 100

    -- 分页获取所有 releases
    while true do
        local url = "https://api.github.com/repos/moonbitlang/moonbit-compiler/releases"
            .. "?per_page=" .. per_page
            .. "&page=" .. page

        local resp, err = http.get({
            url = url,
        })

        if err ~= nil then
            error("获取 MoonBit 版本列表失败: " .. err)
        end

        if resp.status_code ~= 200 then
            error("GitHub API 返回状态码 " .. resp.status_code .. ": " .. (resp.body or ""))
        end

        local releases = json.decode(resp.body)

        -- 如果当前页没有数据，说明已获取完毕
        if #releases == 0 then
            break
        end

        for _, release in ipairs(releases) do
            -- 跳过草稿和预发布版本
            if not release.draft and not release.prerelease then
                local tag_name = release.tag_name
                -- 去掉版本号前缀 "v"
                local version = tag_name:gsub("^v", "")
                table.insert(all_versions, {
                    version = version,
                    note = nil,
                })
            end
        end

        -- 如果返回数量少于 per_page，说明已经是最后一页
        if #releases < per_page then
            break
        end

        page = page + 1
    end

    -- 按版本降序排列（新版本在前）
    table.sort(all_versions, util.compare_versions)

    return all_versions
end