--- A simple unit testing library for Lua
-- @module luatest
-- @author Talon Holton
-- @license MIT

local luatest = {}
luatest.__index = luatest

local codes = {
    stop = '\27[0m',
    red = '\27[31m',
    green = '\27[32m',
    yellow = '\27[33m'
}

luatest.codes = codes

local assertions = {}
assertions.__index = assertions
luatest.assertions = assertions

--- Tests if two values are equal
---@param expected any
---@param actual any
---@param msg ?string
function assertions.equal(expected, actual, msg)
    local message = msg or ('Expected ' .. expected .. ', was ' .. actual)
    assert(expected == actual, message)
end

--- Tests if two values are not equal
---@param expected any
---@param actual any
---@param msg ?string
function assertions.notequal(expected, actual, msg)
    local message = msg or ('Expected not to be ' .. expected .. ', was ' .. actual)
    assert(expected ~= actual, message)
end

--- Tests if a value is true
---@param actual any
---@param msg ?string
function assertions.ok(actual, msg)
    local message = msg or string.format('Expected true, was %s', actual)
    assert(actual, message)
end

--- Fails the test
---@param msg ?string
function assertions.fail(msg)
    local message = msg or 'Test was manually failed'
    assert(false, message)
end

--- Tests if a value is nil
---@param actual any
---@param msg ?string
function assertions.isnil(actual, msg)
    local message = msg or string.format('Expected nil, was %s', actual)
    assert(actual == nil, message)
end

--- Tests if two numbers are nearly equal. Be default, uses a relative tolerance of 1e-4
---@param expected number
---@param actual number
---@param msg ?string
---@param tolerance ?number
---@param absolute ?boolean
function assertions.nearequal(expected, actual, msg, tolerance, absolute)
    local tol = tolerance or 1e-4
    local delta = math.abs(absolute and tol or tol * expected)
    local message = msg or ('Expected ' .. expected .. '+/-' .. delta .. ', was ' .. actual)
    assert(math.abs(expected - actual) < delta, message)
end

--- Creates a new test suite
---@param _ any
---@param name ?string
---@return table
function luatest.new(_, name)
    local self = setmetatable({}, luatest)
    self.name = name or 'Unnamed Suite'
    -- pre and post methods
    self._before = function() end
    self._after = function() end
    -- test lists
    self.tests = {}
    return self
end

-- set call function
setmetatable(luatest, { __call = luatest.new })

--- Adds a new test to the suite
---@param name ?string
---@param test ?function
function luatest:test(name, test)
    local _name = name or ('Unnamed Test ' .. #self.tests)
    local _test = test or function() end
    table.insert(self.tests, { test = _test, name = _name })
end

--- Sets a function to run before all tests
---@param fn ?function
function luatest:before(fn)
    self._before = fn or function() end
end

--- Sets a function to run after all tests
---@param fn ?function
function luatest:after(fn)
    self._after = fn or function() end
end

local function run_test(test, name, width)
    local passed = true
    xpcall(
        function()
            test()
            print(string.format('%-' .. width .. 's%10s', name, codes.green .. 'PASS' .. codes.stop))
        end,
        function(err)
            print(string.format('%-' .. width .. 's%10s', name, codes.red .. 'FAIL' .. codes.stop))
            print(' ' .. err)
            passed = false
        end
    )
    return passed
end

--- Runs all tests in the suite and exits with a proper code (0 for success, number of failed tests for failure)
function luatest:run()
    print(string.format('Running %d Tests for Suite %s', #self.tests, self.name))

    -- find the longest test name
    local width = 0
    for _, t in ipairs(self.tests) do
        width = math.max(width, #t.name)
    end
    width = width + 4

    -- before
    self._before()

    -- run all tests
    local run = 0
    local failed = 0
    for _, t in ipairs(self.tests) do
        run = run + 1
        if run_test(t.test, t.name, width) == false then
            failed = failed + 1
        end
    end

    -- after
    self._after()

    if failed > 0 then
        print()
        print("Run/Passed/Failed :" .. run .. "/" .. run - failed .. "/" .. failed)
        print(codes.red .. 'FAILED' .. codes.stop)
        -- exit with error code equal to number of failed tests
        os.exit(failed)
    else
        if run > 0 then
            print()
            print("Passed/Run: " .. run - failed .. "/" .. run)
        end
        print(codes.green .. 'PASSED' .. codes.stop)
        os.exit(0)
    end
end

-- Return the module
return luatest
