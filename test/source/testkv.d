module testkv;

import grpc;
import clientv3;

import hunt.logging;

void testKV(Channel channel)
{
    auto c = new KVImpl(channel);
    testNormal(c);
    testWithLease(c , channel);
}


void testNormal(KVImpl impl)
{
    enum KEY = "test";
    enum VALUE = "value";

    assert(impl.put(KEY , VALUE));
    string value;
    assert(impl.get(KEY, value));
    assert(value == VALUE);
    assert(impl.del(KEY));
    assert(impl.get(KEY , value));
    assert(value == "");
    logInfo("test ok");
}


void testWithLease(KVImpl impl , Channel channel)
{
   
    enum KEY = "test";
    enum VALUE = "value";

    import core.thread;
    string value;
    long ID;
    int ttl = 5;
    auto impl2 = new LeaseImpl(channel);
    assert(impl2.grant(ttl , ID));
    logInfo("leaseID " , ID);
    assert(impl.put(KEY , VALUE , ID));
    Thread.sleep(dur!"seconds"(6));
    assert(impl.get(KEY , value));
    assert(value == "");
    logInfo("test ok");
     
}