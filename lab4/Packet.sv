`ifndef INC_PACKET_SV
`define INC_PACKET_SV

class Packet;
    rand bit [3:0] sa, da; // 随机变量 
    rand logic [7:0] payload[$];
    string name;
// 属性约束 确定变量的值的范围
    constraint valid {
        sa inside {[0:15]};
        da inside {[0:15]};
        payload.size() inside{[2:4]};
    }	

    extern function new(string name = "Packet");
    extern function bit compare(Packet pkt2cmp, ref string message);
    extern function void display(string prefix = "NOTE");

endclass : Packet

function Packet::new (string name);
    this.name = name;
    
endfunction : new

function bit Packet::compare (Packet pkt2cmp, ref string message);
    if (payload.size() != pkt2cmp_payload.size()) begin
      message = "payload size mismatch";
      message = {message, $sformatf("payload.size() = %0d, pkt2cmp_payload.size() = %0d", payload.size(), pkt2cmp_payload.size())};
      return (0);
    end
    if (payload != pkt2cmp.payload) ;
    else begin 
      message = "payload content mismatch:\n";
      message = {message, $sformatf("Packet Sent:   %p\nPkt Received:   %p", payload, pkt2cmp_payload)};
      return(0);
    end
    message = "successful compared";
    return(1);    

endfunction : compare

function void Packet::display (string prefix);
    $display("[%s]%t %s sa = %0d, da = %0d", prefix, $realtime, name, sa, da);
    foreach(payload[i])
        $display("[%s]%t %s payload[%0d] = %0d", prefix, $realtime, name, i, payload[i]);
endfunction : display


`endif