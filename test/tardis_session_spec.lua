local session = require('tardis-nvim.session')
function session.Session:close()
    self.closed = true
    if self.parent then
        self.parent:on_session_close(self)
    end
end
describe('Sessions', function()
    it ('can be empty', function()
        local s = session.Session:new()
        assert.equals(s.id, 0)
        assert.equals(s.parent, nil)
    end)

    it ('can be initialized', function()
        local s = session.Session:new({
            id = 1,
            parent = nil,
            buffers = {1, 2, 3, 4}
        })
        assert.equals(s.id, 1)
        assert.equals(s.parent, nil)
    end)
end)

describe('SessionManager',function ()
    it ('can be created', function ()
        local sp = session.SessionManager:new()
        assert.equals(sp.next, 1)
        assert.equals(#sp.sessions, 0)
    end)

    it ('can create a single session', function ()
        local sp = session.SessionManager:new()
        local s = sp:create_session({1})

        assert.equals(#sp.sessions, 1)
        assert.equals(sp.next, 2)
        assert.equals(s.id, 1)
        assert.equals(s.parent, sp)
    end)

    it ('can close a created session', function ()
        local sp = session.SessionManager:new()
        local s = sp:create_session({1})

        assert.equals(#sp.sessions, 1)
        assert.equals(sp.next, 2)
        assert.equals(s.id, 1)
        assert.equals(s.parent, sp)
        s:close()
        assert.equals(#sp.sessions, 0)
        assert.equals(s.closed, true)
        assert.equals(sp.next, 2)
        assert.equals(s.id, 1)
        assert.equals(s.parent, sp)

    end)

    it ('can create multiple Sessions', function ()
        local sp = session.SessionManager:new()
        local s1 = sp:create_session({1})
        local s2 = sp:create_session({2})
        local s3 = sp:create_session({3})

        assert.equals(#sp.sessions, 3)
        assert.equals(sp.next, 4)
        assert.equals(s1.id, 1)
        assert.equals(s1.parent, sp)
        assert.equals(s2.id, 2)
        assert.equals(s2.parent, sp)
        assert.equals(s3.id, 3)
        assert.equals(s3.parent, sp)
    end)

end)
