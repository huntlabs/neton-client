module clientv3.watchimpl;

import etcdserverpb.kv;
import etcdserverpb.rpc;
import etcdserverpb.rpcrpc;

import grpc;
import hunt.logging;

import clientv3.watcher;

alias WatchNotify = void delegate(WatchImpl.NotifyItem item);
alias Type = Event.EventType;

class WatchImpl
{

    static class NotifyItem
    {
        long ID;            ///
        Type op;
        string key;         
        string value;       
    }

    WatchClient client;

    this(Channel channel)
    {
        client = new WatchClient(channel);
    }

    Watcher createWatcher(WatchNotify notify)
    {
        auto stream = client.Watch();
        return new Watcher(stream , notify);
    }

}