module testlease;

import grpc;
import clientv3;

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
    assert(res.ID == ID && res.TTL == ttl);
    long[] IDS;
    assert(impl.leases(IDS));
    assert(IDS.length == 1 && IDS[0] == ID);
    assert(impl.revoke(ID));
    assert(impl.timeToLive(ID , res));
    assert(res.ID == 0);
}

void testWithKeepAlive(LeaseImpl impl)
{

}

