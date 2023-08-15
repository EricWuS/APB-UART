//----------------------------------------------------------------------
//   Copyright 2012 Mentor Graphics Corporation
//   All Rights Reserved Worldwide
//
//   Licensed under the Apache License, Version 2.0 (the
//   "License"); you may not use this file except in
//   compliance with the License.  You may obtain a copy of
//   the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in
//   writing, software distributed under the License is
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied.  See
//   the License for the specific language governing
//   permissions and limitations under the License.
//----------------------------------------------------------------------

class uart_host_rx_seq extends host_if_base_seq;

`uvm_object_utils(uart_host_rx_seq)

rand int no_rx_chars; // 在UART主机接收数据时，要接收的字符数

constraint char_limit_c { no_rx_chars inside {[1:20]};}

function new(string name = "uart_host_rx_seq");
  super.new(name);
endfunction

task body;
  super.body();
  for(int i = 0; i < no_rx_chars; i++) begin
    rm.LSR.read(status, data, .parent(this));
    // Wait for data to be available
    // 问题：LSR[0]bit位为0时，是FIFO空的指示；为1时，则代表至少还有一个数据在FIFO中
    // 此处的while循环条件是否出现错误，当FIFO为空时，再进行LSR的读操作，直到LSR[0] Data Ready拉高，表明有数据了。
    // 解答：在循环中再次进行读操作是为了确保 DR 位的状态已经稳定，以避免在数据传输过程中出现错误。
    // 这种等待 DR 位变为 1 的方式是常见的 UART 数据接收方式，
    // 可以保证在接收到有效数据之后才进行读取操作，从而提高了验证的可靠性。
    while(!data[0]) begin
      rm.LSR.read(status, data, .parent(this));
      cfg.wait_for_clock(10);
    end
    rm.RXD.read(status, data, .parent(this));
  end
endtask: body

endclass: uart_host_rx_seq
