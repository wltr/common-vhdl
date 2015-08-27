## Common VHDL Components

### Generic
- Delay
- Edge detector
- Glitch filter
- Majority voting glitch filter
- External input synchronization
- Reset generator
- Strobe generator
- Strobe generator using LFSR counters
- Bit clock recovery
- Stop watch
- Memory data triplication and voting
- Array transmitter (for e.g. UART)

### Communication
- UART
- Serial 3-wire transceiver (bit clock, frame, data)

### DSP
- FIR filter for the ADS1281 delta-sigma ADC

### Interfaces
- External SRAM interface (tested with Renesas and Cypress memories)
- Interface for the MAX5541 DAC

### Memory
- Basic FIFO + TMR version
- Single-port RAM + TMR version
- Two-port RAM + TMR version

#### Packages
- Linear feedback shift registers (LFSRs)

### Platform specific
Microsemi:
- Reset generator leveraging the power-up delay between input and output buffers
