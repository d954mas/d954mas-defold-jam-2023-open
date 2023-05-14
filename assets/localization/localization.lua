local I18N = require "libs.i18n.init"
local LOG = require "libs.log"
local CONSTANTS = require "libs.constants"
local TAG = "LOCALIZATION"
local LUME = require "libs.lume"
local LOCALES = { "en", "ru" }
local DEFAULT = CONSTANTS.LOCALIZATION.DEFAULT
local FALLBACK = DEFAULT

---@class Localization
local M = {
	first_floor_awake = { en = "Ohh my head. What happened, I don't remember anything.", ru = "Охх, моя голова. Что случилось, ничего не помню." },
	first_floor_todo = { en = "Need to look around", ru = "Нужно осмотреться" },
	first_floor_door_closed = { en = "This door is closed. Looks like I'll have to go down.", ru = "Эта дверь закрыта. Похоже придется спускать вниз." },
	floor_11_no_way_closed = { en = "There is no way. What should I do? I'll try to go back", ru = "Нет прохода. Что мне делать? Попробую вернутся назад" },
	floor_9_no_way_back = { en = "What? Wall? I just got down from there.", ru = "Что? Стена? Я только что спускался оттуда." },
	dialog_flashlight = { en = "It got darker. Lucky I have a flashlight", ru = "Стало темнее. Повезло что у меня есть фонарик" },
	floor_28_no_floor = { en = "The floor is gone, I need to be more careful", ru = "Пол пропал мне ужно быть аккуратнее" },
	tooltip_use_flashlight = { en = "Press \"F\" to turn on the flashlight", ru = "Нажмите \"F\" чтобы включить фонарик" },
	tooltip_use_flashlight_mobile = { en = " ", ru = " " },
}

function M:locale_exist(key)
	local locale = self[key]
	if not locale then
		LOG.w("key:" .. key .. " not found", TAG, 2)
	end
end

function M:set_locale(locale)
	LOG.w("set locale:" .. locale, TAG)
	I18N.setLocale(locale)
end

function M:locale_get()
	return I18N.getLocale()
end

I18N.setFallbackLocale(FALLBACK)
M:set_locale(DEFAULT)
if (CONSTANTS.LOCALIZATION.FORCE_LOCALE) then
	LOG.i("force locale:" .. CONSTANTS.LOCALIZATION.FORCE_LOCALE, TAG)
	M:set_locale(CONSTANTS.LOCALIZATION.FORCE_LOCALE)
elseif (CONSTANTS.LOCALIZATION.USE_SYSTEM) then
	local system_locale = sys.get_sys_info().language
	LOG.i("system locale:" .. system_locale, TAG)
	if (LUME.findi(LOCALES, system_locale)) then
		M:set_locale(system_locale)
	else
		LOG.i("unknown system locale:" .. system_locale, TAG)
		pprint(LOCALES)
	end

end

for _, locale in ipairs(LOCALES) do
	local table = {}
	for k, v in pairs(M) do
		if type(v) ~= "function" then
			table[k] = v[locale]
		end
	end
	I18N.load({ [locale] = table })
end

for k, v in pairs(M) do
	if type(v) ~= "function" then
		M[k] = function(data)
			return I18N(k, data)
		end
	end
end

--return key if value not founded
---@type Localization
local t = setmetatable({ __VALUE = M, }, {
	__index = function(_, k)
		local result = M[k]
		if not result then
			LOG.w("no key:" .. k, TAG, 2)
			result = function() return k end
			M[k] = result
		end
		return result
	end,
	__newindex = function() error("table is readonly", 2) end,
})

return t
