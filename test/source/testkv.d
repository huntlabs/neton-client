module testkv;

import grpc;
import clientv3;

void testKV(Channel channel)
{
    auto c = new KVImpl(channel);
    testNormal(c);
    testWithLease(c);
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
}


void testWithLease(KVImpl impl)
{

}