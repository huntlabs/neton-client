module testlease;

import grpc;
import clientv3;
import hunt.logging;
import hunt.util.serialize;

void testLease(Channel channel)
{
    auto c = new LeaseImpl(channel);
    testNormal(c);
    testWithKeepAlive(c);
}


void testNormal(LeaseImpl impl)
{
    import core.thread;

    long ttl = 10;
    long ID;
    assert(impl.grant(ttl , ID));
    LeaseImpl.TimeToLiveRes res;
    assert(impl.timeToLive(ID , res));
    assert(res.ID == ID && res.grantedTTL == ttl);
    
    /* etcd 3.2.18 no this function.
    long[] IDS;
    assert(impl.leases(IDS));
    assert(IDS.length == 1 && IDS[0] == ID);
    */
    assert(impl.revoke(ID));
    assert(impl.timeToLive(ID , res));
    assert(res.grantedTTL == 0 && res.TTL == -1);
    logInfo("test ok");
}

void testWithKeepAlive(LeaseImpl impl)
{
    import core.thread;
    long ttl = 3;
    long ID;
    assert(impl.grant(ttl , ID));
    impl.openKeepalive(ID);
    
    LeaseImpl.TimeToLiveRes res;
    // Thread.sleep(dur!"seconds"(4));
    assert(impl.timeToLive(ID , res));
    import std.format;
    logInfo("(ID , grantedTTL) : (%s , %s)".format(res.ID,res.grantedTTL));
    assert(res.ID == ID && res.grantedTTL == ttl);
    impl.closeKeepalive(ID);

    Thread.sleep(dur!"seconds"(4));
    assert(impl.timeToLive(ID , res));
    logInfo("(ID , TTL , grantedTTL) : (%s , %s,%s)".format(res.ID,res.TTL,res.grantedTTL));
    assert(res.grantedTTL == 0 && res.TTL == -1);
    logInfo("test ok");
}

