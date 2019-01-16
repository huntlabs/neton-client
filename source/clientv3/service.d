module clientv3.service;
import etcdserverpb.kv;
import etcdserverpb.rpc;
import etcdserverpb.rpcrpc;
import clientv3.kvimpl;

import grpc;
import hunt.logging;
import hunt.util.Serialize;


class Service
{
    static struct Meta
    {
        string addr;  
        string data;
    }

    KVImpl kv;


    this(Channel chanel)
    {
        kv = new KVImpl(chanel);
    }

    bool registerInstance(string serviceName , string addr  , string data = string.init , long leaseID = 0)
    {
        Meta meta;
        meta.addr = addr;
        meta.data = data;
        if(!kv.put(serviceName ~ "/" ~ addr ,cast(string) serialize(meta) , leaseID))
            return false;
        return true;
    }

    bool deregisterInstance(string serviceName , string addr)
    {
        if(!kv.del(serviceName ~ "/" ~ addr))
            return false;
        return true;
    }

    bool deregisterAll(string serviceName)
    {
        if(!kv.del(serviceName))
            return false;
        return true;
    }

    Meta[] getAllInstances(string serviceName)
    {
        
        string[] values;
        if(!kv.get(serviceName ~ "/" , values))
            return null;
        
        Meta[] list;
        foreach(v ; values)
            list ~= unserialize!Meta(cast(byte[])v);

        return list;
    }


}