module nacos.namingservice;


import nacos.namingevent;
import nacos.instance;
import nacos.event;
import nacos.eventlistener;
import clientv3;
import grpc;
import hunt.logging;
import std.string;

class NamingService
{
    Service service;
    Watcher watcher;
    EventListener[string] listeners;
    long[string]     listenerids;

    this(Channel channel)
    {   
        service = new Service(channel);
        watcher = new WatchImpl(channel).createWatcher((WatchImpl.NotifyItem item){
            
            auto serviceName = item.key.split("/")[0];
            synchronized(this){
                auto l  = serviceName in listeners;
                if(l != null)
                {
                    auto e = new NamingEvent(serviceName , getAllInstances(serviceName));
                    l.onEvent(e);
                }
            }
        });
    }

    bool registerInstance(string serviceName , string addr  , string data = string.init )
    {
        return service.registerInstance(serviceName , addr , data);
    }
    bool deregisterInstance(string serviceName , string addr)
    {
        return service.deregisterInstance(serviceName , addr);

    }
    Instance[] getAllInstances(string serviceName)
    {
        Instance[] insList;
        auto list = service.getAllInstances(serviceName);
        foreach(l ; list)
        {
            Instance ins;
            ins.addr = l.addr;
            ins.data = l.data;
            insList ~= ins;
        }
        return insList;
    }

    void subscribe(string serviceName, EventListener listener)
    {
        long ID;
        if(!watcher.watch(serviceName , ID))
        {
            logError("subscribe error");
            return ;
        }
        synchronized(this){
            if( serviceName in listenerids)
                unsubscribe(serviceName , listener);

            listeners[serviceName] = listener;
            listenerids[serviceName] = ID;
        }

    }

    void unsubscribe(string serviceName, EventListener listener)
    {
       synchronized(this){
            auto id = serviceName in listenerids;
            if(id == null)
            {
                logError("no this id watcher");
                return ;
            }
            listenerids.remove(serviceName);
            listeners.remove(serviceName);
            watcher.cancel(*id);
        }
    }

}