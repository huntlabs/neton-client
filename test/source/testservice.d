module testservice;

import grpc;
import clientv3;

import hunt.logging;
import hunt.util.Serialize;
import core.thread;
import core.time;
import hunt.util.Serialize;

void testService(Channel channel)
{
    auto service = new Service(channel);
    testNormal(service , channel);
    logInfo("test ok");
}




void testNormal(Service service , Channel channel)
{
    enum SERVICE = "test";
    enum ADDR1 = "1.1.1.1:1001";
    enum ADDR2 = "1.1.1.2:1001";
    enum ADDR3 = "1.1.1.3:1001";
    long ID;
    Service.Meta[] list;

    ///watch
    int cnt = 0;
    WatchImpl watch = new WatchImpl(channel);
    auto watcher = watch.createWatcher((WatchImpl.NotifyItem item){
        logError(item.key , " " , item.op);
        switch(cnt){
            case 0:
                assert(item.key == SERVICE ~ "/" ~ ADDR1);
                break;
            case 1:
                assert(item.key == SERVICE ~ "/" ~ ADDR2);
                break;
            case 2:
                assert(item.key == SERVICE ~ "/" ~ ADDR3);
                break;
            case 3:
                assert(item.key == SERVICE ~ "/" ~ ADDR1 && item.op == Type.DELETE);
                break;
            case 4:
                assert(item.key == SERVICE ~ "/" ~ ADDR2 && item.op == Type.DELETE);
                break;
            case 5:
                assert(item.key == SERVICE && item.op == Type.DELETE);
            default:
                assert(0);
        }
        cnt++;
    });

    watcher.watch(SERVICE , ID);

    service.registerInstance(SERVICE , ADDR1 );
    service.registerInstance(SERVICE , ADDR2 );
    service.registerInstance(SERVICE , ADDR3 );
    list = service.getAllInstances(SERVICE);
    logInfo("service list1 : ",list);
    assert(list.length == 3 && list[0].addr == ADDR1 && list[1].addr == ADDR2 && list[2].addr == ADDR3 );
    service.deregisterInstance(SERVICE , ADDR1);
    list = service.getAllInstances(SERVICE);
    logInfo("service list2 : ",list);
    assert(list.length == 2 && list[0].addr == ADDR2 && list[1].addr == ADDR3 );
    service.deregisterInstance(SERVICE , ADDR2);

    watcher.cancel(ID);

    service.deregisterInstance(SERVICE , ADDR3);
    list = service.getAllInstances(SERVICE);
    logInfo("service list3 : ",list);
    assert(list.length == 0);
    service.deregisterAll(SERVICE);

    Thread.sleep(dur!"seconds"(3));
    logError(" ---cnt : ",cnt);
    assert(cnt == 5);
}

