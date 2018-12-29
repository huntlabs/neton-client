module testwatch;

import grpc;
import clientv3;

import hunt.logging;
import hunt.util.serialize;
import core.thread;
import core.time;


void testWatch(Channel channel)
{
    testNormal(channel);
}


void testNormal(Channel channel)
{
    WatchImpl impl = new WatchImpl(channel);
    enum KEY1 = "key1";
    enum VALUE1 = "value1";
    enum KEY2 = "key2";
    enum VALUE2 = "value2";
    int cnt = 0;
    long ID1;
    long ID2;
    auto watcher = impl.createWatcher((WatchImpl.NotifyItem item){
        if(cnt == 0)
        {
            assert(item.ID == ID1 && 
            item.op == Type.PUT &&
            item.value == VALUE1 && item.key == KEY1);
        }
        else if(cnt == 1 || cnt == 4)
        {
            assert(item.ID == ID2 && 
            item.op == Type.PUT &&
            item.value == VALUE2 && item.key == KEY2);
        }
        else if(cnt == 2)
        {
            assert(item.ID == ID1 && 
            item.op == Type.DELETE && item.key == KEY1);
        }
        else if(cnt == 3)
        {
            assert(item.ID == ID2 && 
            item.op == Type.DELETE  && item.key == KEY2);
        }
        cnt++;
        assert(cnt <= 5);
    });
    assert(watcher.watch(KEY1 , ID1));
    assert(watcher.watch(KEY2 , ID2));

    auto kvimpl = new KVImpl(channel);
    assert(kvimpl.put(KEY1 , VALUE1));
    assert(kvimpl.put(KEY2 , VALUE2));
    assert(kvimpl.del(KEY1));
    assert(kvimpl.del(KEY2));

    assert(watcher.cancel(ID1));
    kvimpl.put(KEY1 , VALUE1);
    kvimpl.put(KEY2 , VALUE2);
    
    assert(watcher.cancel(ID2));
    assert(kvimpl.del(KEY1));
    assert(kvimpl.del(KEY2));
    Thread.sleep(dur!"seconds"(1));
    assert(cnt == 5);
    logInfo("test ok");
    

}