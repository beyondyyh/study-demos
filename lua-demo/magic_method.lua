-- __index方法，在表中查找键不存在时转而在元表中查找该键：
local mytable = setmetatable({ key1 = "value1" }, -- 原始表
    {
        __index = function(self, key) -- 重载函数
            if key == "key2" then
                return "metatablevalue"
            end
        end
    }
)

print(mytable.key1, mytable.key2) --> output：value1 metatablevalue

-- __tostring 与Java的toString()函数类似，可以实现自定义的字符串转换
local arr = { 1, 2, 3, 4 }
arr = setmetatable(arr, { __tostring = function(self)
    local result = '{'
    local sep = ''
    for _, i in ipairs(self) do
        result = result .. sep .. i
        sep = ', '
    end
    result = result .. '}'
    return result
end })

print(arr)


-- __call方法类似于C++中的仿函数，使普通的元表也可以被调用
local functor = {}
local function func1(self, arg)
    print("called from", arg)
end

setmetatable(functor, { __call = func1 })

functor("functor") --> called from functor
print(functor) --> table: 0x7f9daec0a420，地址可能不一样

-- __metatable元方法
-- 假如我们想保护我们的对象使其使用者既看不到也不能修改 metatables。我们可以对 metatable 设置了 __metatable 的值，
-- getmetatable 将返回这个域的值，而调用 setmetatable 将会出错：

Object = setmetatable({}, { __metatable = "You cannot access here" })
print(getmetatable(Object)) --> You cannot access here
setmetatable(Object, {}) --> cannot change a protected metatable
