-- Hunk review bridge. Press cmd+shift+r from the agent pane: the review
-- opens beside it, and ctrl+g in Hunk stages its notes as the agent's next
-- prompt. Pressing the key again focuses the existing review.
--
-- Placement lives here, not in the binding. Bind another key to the same
-- action with an argument:
--   rex.bind("shift+alt+cmd+r", "hunk_review", { placement = "float" })
--   rex.bind("shift+alt+cmd+t", "hunk_review", { placement = "tab" })
local terminal = "com.superlogical.terminal"
local shells = { zsh = true, bash = true, fish = true, sh = true, nu = true }
local last_agent = nil

local function process_of(block_id)
  local p = rex.block.call(terminal, "process", { block_id = block_id })
  if not p then return nil end
  return p.foreground or p.child
end

rex.action{
  name = "hunk_review",
  title = "Review in Hunk",
  description = "Open a live Hunk review and hand its notes back to the agent in this pane",
  category = "Review",
  args = {
    type = "object",
    properties = {
      placement = {
        type = "string",
        enum = { "split", "down", "float", "tab" },
        description = "Where the review opens. Defaults to split.",
      },
    },
    additionalProperties = false,
  },
  run = function(ctx, args)
    local focused = ctx.block_id
    if not focused then error("no focused pane", 0) end

    local current = process_of(focused)
    if current and shells[current.name] then
      error("focus the agent pane first", 0)
    end

    -- Pressing the key again from the review pane returns to the pane it was
    -- opened for, so reuse checks look at the right worktree.
    local agent = focused
    if current and current.name == "hunk" and last_agent then
      agent = last_agent
    end
    last_agent = agent

    local info = process_of(agent)
    local cwd = info and info.cwd or nil

    -- Reuse the review already open for this worktree.
    local view = rex.session.view({})
    for _, win in ipairs(view and view.windows or {}) do
      for _, layer in ipairs(win.layers or {}) do
        for _, b in ipairs(layer.blocks or {}) do
          if b.block_id ~= agent then
            local p = process_of(b.block_id)
            if p and p.name == "hunk" and cwd ~= nil and p.cwd == cwd then
              rex.session.focus_block{ block_id = b.block_id }
              return { block_id = b.block_id, reused = true }
            end
          end
        end
      end
    end

    local home = os.getenv("HOME") or ""
    local layout = {
      block = {
        flavor = terminal .. ".shell",
        label = "hunk",
        options = {
          cwd = cwd,
          command = {
            "env",
            "REX_AGENT_BLOCK=" .. agent,
            "/etc/profiles/per-user/matt/bin/hunk",
            "--extension",
            home .. "/.config/hunk/extensions/rex-handoff.ts",
            "diff",
          },
        },
      },
    }

    local placement = args.placement or "split"
    local result, err
    if placement == "float" then
      result, err = rex.session.new_layer{
        bounds = { x = 0.12, y = 0.08, w = 0.76, h = 0.84 },
        focus = true,
        layout = layout,
      }
    elseif placement == "tab" then
      result, err = rex.session.new_window{
        window_label = "hunk",
        focus = true,
        layout = layout,
      }
    elseif placement == "down" then
      result, err = rex.session.new_split{
        anchor_id = agent,
        direction = "vertical",
        side = "after",
        ratio = 0.5,
        focus = true,
        layout = layout,
      }
    else
      result, err = rex.session.new_split{
        anchor_id = agent,
        direction = "horizontal",
        side = "after",
        ratio = 0.5,
        focus = true,
        layout = layout,
      }
    end
    if err then error(err, 0) end
    return result
  end,
}

rex.bind("cmd+shift+r", "hunk_review")
