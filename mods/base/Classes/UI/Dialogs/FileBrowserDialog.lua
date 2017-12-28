FileBrowserDialog = FileBrowserDialog or class(MenuDialog)
FileBrowserDialog._no_clearing_menu = true
FileBrowserDialog._no_reshaping_menu = true
FileBrowserDialog.type_name = "FileBrowserDialog"
function FileBrowserDialog:_Show(params, force)
    if not self:basic_show(params) then
        return
    end
    self._extensions = params.extensions
    self._file_click = params.file_click
    self._base_path = params.base_path
    self._browse_func = params.browse_func
    self:Browse(params.where or string.gsub(Application:base_path(), "\\", "/"))
    self:show_dialog()
end

function FileBrowserDialog:init(params, menu)  
    if self.type_name == FileBrowserDialog.type_name then
        params = params and clone(params) or {}
    end

    menu = menu or BLT.Dialogs:Menu()
    local items_size = params.items_size or 32
    local h = 700
    FileBrowserDialog.super.init(self, table.merge(params, {
        w = 1300,
        h = items_size + 4,
        auto_height = false,
        position = function(item)
            item:SetPositionByString("Center")
            item:Panel():move(0, -h/2)
        end,
        align_method = "grid",
        offset = 0
    }), menu)

    self._folders_menu = menu:Menu(table.merge(params, {
        w = 500,
        h = h  ,
        background_color = params.background_color or Color(0.6, 0.2, 0.2, 0.2),
        name = "Folders",
        position = function(item)
            item:Panel():set_position(self._menu:Panel():leftbottom())
        end,
        auto_height = false,
        visible = false
    })) 

    self._files_menu = menu:Menu(table.merge(params, {
        name = "Files",
        w = 800,
        position = function(item)
            item:Panel():set_righttop(self._menu:Panel():rightbottom())
        end
    }))

    self._menus = {self._files_menu, self._folders_menu}
    local path_and_search = (0.85 * self._menu:Width())
    local rest = (0.15 * self._menu:Width()) / 3
    self._menu:Button({
        name = "Backward",
        w = rest,
        h = self._menu.h,
        text = "<",
        text_align = "center",
        callback = callback(self, self, "FolderBack"),  
        label = "temp"
    })    
    enabled = self._old_dir and self._old_dir ~= self._current_dir or false
    self._menu:Button({
        name = "Forward",
        w = rest,
        h = self._menu.h,
        text = ">",
        text_align = "center",
        callback = function()
            self:Browse(self._old_dir)
        end,  
        label = "temp"
    })    
    self._menu:TextBox({
        name = "CurrentPath",
        text = false,
        w = path_and_search * 0.65,
        control_slice = 1,
        forbidden_chars = {':','*','?','"','<','>','|'},
        callback = callback(self, self, "OpenPathSetDialog"),
    })
    self._menu:TextBox({
        name = "Search",
        w = path_and_search * 0.35,
        control_slice = 0.7,
        callback = callback(self, self, "Search"),  
        label = "temp"
    })
    self._menu:ImageButton({
        name = "Close",
        w = rest,
        h = self._menu.h,
        offset = offset,
        icon_w = 24,
        icon_h = 24,
        img_rot = 45,
        texture = "ui/atlas/raid_atlas_menu",
        texture_rect = {761, 721, 18, 18},
        callback = callback(self, self, "hide"),  
        label = "temp"
    })
    self._search = ""
end

function FileBrowserDialog:Browse(where, params)
    if not FileIO:Exists(where) then
        return
    end
    self._files_menu:ClearItems()
    self._folders_menu:ClearItems()
    if self._current_dir ~= where then
        self._search = ""
        self._menu:GetItem("Search"):SetValue("")
    end
    self._current_dir = where or ""
    local enabled = where ~= self._base_path
    self._menu:GetItem("CurrentPath"):SetValue(where)
    self._menu:GetItem("Backward"):SetEnabled(enabled)
    self._menu:GetItem("Forward"):SetEnabled(enabled)
    local f = {}
    local d = {}
    if self._browse_func then  
        f, d = self._browse_func(self)
    else
        f = SystemFS:list(where)
        d = SystemFS:list(where, true)
    end
    if self._search:len() > 0 then
        local temp_f = clone(f)
        local temp_d = clone(d)
        f = {}
        d = {}
        for _, v in pairs(temp_f) do
            if v:match(self._search) then
                table.insert(f, v)
            end
        end
        for _, v in pairs(temp_d) do
            if v:match(self._search) then
                table.insert(d, v)
            end
        end
    end
    self:MakeFilesAndFolders(f, d)
end

function FileBrowserDialog:MakeFilesAndFolders(files, folders)
    for _,v in pairs(files) do
        local tbl = type(v) == "table"
        local pass = true
        if self._extensions then
            for _, ext in pairs(self._extensions) do
                if ext == Path:GetFileExtension(v) then
                    pass = true
                    break
                else
                    pass = false
                end
            end
        end
        if pass then
            self._files_menu:Button({
                name = tbl and v.name or v,
                text = tbl and v.name or v,
                path = tbl and v.path or Path:Combine(self._current_dir, v),
                callback = callback(self, self, "FileClick"), 
                label = "temp2",
            })
        end       
    end       
    for _,v in pairs(folders) do
         self._folders_menu:Button({
            name = v,
            text = v,
            callback = callback(self, self, "FolderClick"), 
            label = "temp2"
        })        
    end
end

function FileBrowserDialog:Search(menu, item)
    self._search = item:Value()
    self:Browse(self._current_dir)
end

function FileBrowserDialog:OpenPathSetDialog(menu, item)
    self:Browse(item:Value())
end

function FileBrowserDialog:FileClick(menu, item)
    if self._file_click then
        self._file_click(item.path)
    end
end 

function FileBrowserDialog:FolderClick(menu, item)
    self._old_dir = nil
    self:Browse(self._current_dir .. "/" .. item.text)
    if item.press_clbk then
        item.press_clbk()
    end
end

function FileBrowserDialog:FolderBack()
    if self._searching then
        self._searching = false
        self:Browse()
    else
        local str = string.split(self._current_dir, "/")
        table.remove(str)
        self._old_dir = self._current_dir
        self:Browse(table.concat(str, "/"))
    end 
end

function FileBrowserDialog:hide(...)
    if FileBrowserDialog.super.hide(self, ...) then
        self._current_dir = nil
        self._old_dir = nil
        self._extensions = nil
        self._file_click = nil
        self._browse_func = nil
        self._base_path = nil
        return true
    end
end