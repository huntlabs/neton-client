module nacos.configservice;

import etcdserverpb.kv;
import etcdserverpb.rpc;
import etcdserverpb.rpcrpc;
import clientv3;

import nacos.listener;


import grpc;
import hunt.logging;


class ConfigService
{
    KVImpl kv;
    Watcher watcher;
    Listener[string] listeners;
    long[string]     listenerids;

    this(Channel channel)
    {
        kv = new KVImpl(channel);
        watcher = new WatchImpl(channel).createWatcher((WatchImpl.NotifyItem item){
            synchronized(this){
                auto l = item.key in listeners;
                if(l != null)
                {
                    l.receiveConfigInfo(item.value);
                }
            }
        });
    }
    
    public string getConfig(string group)
    {
        string result;
        kv.get(group , result);
        return result;
    }

    public void addListener(string group,  Listener listener)
    {
        long ID;
        if(!watcher.watch(group , ID))
        {
            logError("watch error");
            return ;
        }
        synchronized(this){
            if( group in listenerids)
                removeListener(group , listener);

            listenerids[group] = ID;
            listeners[group] = listener;
        }
    }

    public void removeListener(string group, Listener )
    {
        synchronized(this){
            auto id = group in listenerids;
            if(id == null)
            {
                logError("no this id watcher");
                return ;
            }
            listenerids.remove(group);
            listeners.remove(group);
            watcher.cancel(*id);
        }

    }

    public bool publishConfig( string group, string content)
    {
        return kv.put(group , content);
    }
}