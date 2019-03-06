module TestRegistry;

import grpc;
import client.registry.RegistryService;
import client.registry.Instance;

import hunt.logging;
import hunt.util.Serialize;
import core.thread;
import core.time;
import hunt.util.Serialize;
import std.conv;
import client.Listener;
import client.Event;


void testRegistry(Channel channel)
{
    auto service = new RegistryService(channel);
    testNormal(service , channel);
    logInfo("test registry ok");
}


void testNormal(RegistryService service , Channel channel)
{
    enum SERVICE = "test";
    enum PORT = 1001;
    enum ADDR1 = "1.1.1.1";
    enum ADDR2 = "1.1.1.2";
    enum ADDR3 = "1.1.1.3";
    long ID;
    Instance[] list;

    ///watch
    service.subscribe(SERVICE,new class Listener{
        override void onEvent(Event event)
        {
            logInfo("service listen : ",event);
        }
    });

    service.registerInstance(SERVICE , ADDR1 , PORT);
    service.registerInstance(SERVICE , ADDR2 , PORT);
    service.registerInstance(SERVICE , ADDR3 , PORT);

    list = service.getAllInstances(SERVICE);
    logInfo("service list1 : ",list);
    assert(list.length == 3 && list[0].ip == ADDR1 && list[1].ip == ADDR2 && list[2].ip == ADDR3 );
    service.deregisterInstance(SERVICE , ADDR1,PORT);
    Thread.sleep(dur!"seconds"(1));

    list = service.getAllInstances(SERVICE);
    logInfo("service list2 : ",list);
    assert(list.length == 2 && list[0].ip == ADDR2 && list[1].ip == ADDR3 );
    service.deregisterInstance(SERVICE , ADDR2,PORT);


    service.deregisterInstance(SERVICE , ADDR3,PORT);
    Thread.sleep(dur!"seconds"(1));

    list = service.getAllInstances(SERVICE);
    logInfo("service list3 : ",list);
    assert(list.length == 0);

    Thread.sleep(dur!"seconds"(1));
}

