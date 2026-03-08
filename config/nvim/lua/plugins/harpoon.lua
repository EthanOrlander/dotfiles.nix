return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local harpoon = require("harpoon")
    -- REQUIRED
    harpoon:setup()
    -- Basic Harpoon configuration
    vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end, { desc = "Harpoon: Add file" })
    vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end,
      { desc = "Harpoon: Toggle menu" })

    -- Remove current file from Harpoon list
    vim.keymap.set("n", "<leader>hr", function() harpoon:list():remove() end,
      { desc = "Harpoon: Remove current file" })

    -- Clear all files from Harpoon list
    vim.keymap.set("n", "<leader>hc", function() harpoon:list():clear() end,
      { desc = "Harpoon: Clear all files" })

    -- Navigation between marked files (QWERTY-friendly)
    -- Using leader+number keys for direct file access
    vim.keymap.set("n", "<leader>1", function() harpoon:list():select(1) end, { desc = "Harpoon: Jump to file 1" })
    vim.keymap.set("n", "<leader>2", function() harpoon:list():select(2) end, { desc = "Harpoon: Jump to file 2" })
    vim.keymap.set("n", "<leader>3", function() harpoon:list():select(3) end, { desc = "Harpoon: Jump to file 3" })
    vim.keymap.set("n", "<leader>4", function() harpoon:list():select(4) end, { desc = "Harpoon: Jump to file 4" })
    -- Toggle previous & next buffers stored within Harpoon list
    vim.keymap.set("n", "<leader>hp", function() harpoon:list():prev() end, { desc = "Harpoon: Prev file" })
    vim.keymap.set("n", "<leader>hn", function() harpoon:list():next() end, { desc = "Harpoon: Next file" })

    -- Configure menu keybindings
    harpoon:extend({
      UI_CREATE = function(cx)
        local conf = require("harpoon").config.menu

        -- Remove current item using Lua indexed removal
        vim.keymap.set("n", "d", function()
          -- Get the current row and remove the item at that index
          local row = vim.api.nvim_win_get_cursor(0)[1]

          -- The Harpoon list is 1-indexed
          if row >= 1 and row <= harpoon:list():length() then
            -- First get the item to select it properly
            local item = harpoon:list():get(row)
            if item then
              -- Select the item (makes it the "current" file)
              harpoon:list():select(row)
              -- Then use the standard remove() method
              harpoon:list():remove()
              -- Refresh the menu
              harpoon.ui:toggle_quick_menu(harpoon:list())
              harpoon.ui:toggle_quick_menu(harpoon:list())
            end
          end
        end, { buffer = cx.bufnr, desc = "Harpoon: Remove item" })

        -- Clear all items from menu
        vim.keymap.set("n", "D", function()
          harpoon:list():clear()
          -- Refresh the menu (it will be empty)
          harpoon.ui:toggle_quick_menu(harpoon:list())
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end, { buffer = cx.bufnr, desc = "Harpoon: Clear all items" })
      end
    })
  end,
}
