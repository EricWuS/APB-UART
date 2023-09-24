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
//   
//   function: 初始化数据接收发送对象的数目，通过各个组件的sequencer挂载不同的sequence
//----------------------------------------------------------------------
class word_format_poll_vseq extends uart_vseq_base;

  `uvm_object_utils(word_format_poll_vseq)

  function new(string name = "word_format_poll_vseq");
    super.new(name);
  endfunction

  task body;
    uart_config_seq setup = uart_config_seq::type_id::create("setup");
    uart_host_rx_seq host_rx = uart_host_rx_seq::type_id::create("host_rx");
    uart_host_tx_seq host_tx = uart_host_tx_seq::type_id::create("host_tx");
    uart_rx_seq rx_serial = uart_rx_seq::type_id::create("rx_serial");
    bit[7:0] lcr;
    bit[15:0] divisor;
    bit[1:0] fcr;  
    // bit [7:0] i;
    lcr = 0;
    divisor = 2;

    host_rx.no_rx_chars = 1;
    host_tx.no_tx_chars = 1;
    rx_serial.no_rx_chars = 1;
    // rx_serial.no_errors = 1;
    rx_serial.no_errors = 0;
    // i = 0;
    repeat(1) begin
      assert(setup.randomize() with {setup.LCR == lcr;
                                    setup.DIV == divisor;
                                    setup.FCR == 2'b01;});
      setup.start(apb);
      rx_serial.baud_divisor = divisor;
      rx_serial.lcr = lcr;
      rx_uart_config.baud_divisor = divisor;
      rx_uart_config.lcr = lcr;
      tx_uart_config.baud_divisor = divisor * 10;
      tx_uart_config.lcr = lcr;

      $display("rx_uart_config.baud_divisor = ", rx_uart_config.baud_divisor);
      $display("tx_uart_config.baud_divisor = ", tx_uart_config.baud_divisor);

      fork
        host_rx.start(apb);     // apb端口检测数据内容data
        host_tx.start(apb);
        rx_serial.start(uart);   // UART端检测pe,fe,sbe等
      join
      lcr = lcr + 1;  // setup.LCR-定义的位数为[5:0] 最大值max= 6'b111111 = 63
      // i++;
      // if (i > 50) begin
      //   rx_serial.no_errors = 1;
      // end
    end

  endtask: body

endclass: word_format_poll_vseq