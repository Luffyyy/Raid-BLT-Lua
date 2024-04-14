BLTLocalization = BLTLocalization or class()

function BLTLocalization:init()
    self.default_language_code = SystemInfo:language():key() -- backwards compat
    self._current = self.default_language_code               -- backwards compat
end
