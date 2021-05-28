<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->

[![MIT License][license-shield]][license-url]

<!-- PROJECT LOGO -->
<br />
<p align="center">  
  <h3 align="center">DAT096-NN1</h3>
  <p align="center">
    Repository for the DAT096 group project
  </p>
</p>

<!-- TABLE OF CONTENTS -->
<details open="open">
  <summary><h2 style="display: inline-block">Table of Contents</h2></summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li><a href="#contributors">Contributors</a></li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#acknowledgements">Acknowledgements</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

This project was developed as part of Chalmers University's DAT096 course during the spring of 2021. It aims to implement a pre-trained image recognition neural network into an FPGA.

Check our sister project at [DAT096-NN1_matlab](https://github.com/rafaelromon/DAT096-NN1_matlab) for the neural network implementation in Matlab.

### Built With

* [Vivado 2019.2](https://www.xilinx.com/products/design-tools/vivado.html)

## Contributors

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore -->
<table align="center">
  <tr>
    <td align="center"><a href="https://github.com/anOrdinarySebastian">
        <img src="https://avatars.githubusercontent.com/u/75024664?v=4"
        width="150px;" alt="anOrdinarySebastian"/><br/><sub><b>Sebastian Bengtsson</b></sub></a><br/></td>  
    <td align="center"><a href="https://github.com/Johnilsa">
        <img src="https://avatars.githubusercontent.com/u/78208966?v=4"
        width="150px;" alt="Johnilsa"/><br/><sub><b>Johan Nilsson</b></sub></a><br/></td>
    <td align="center"><a href="https://github.com/rafaelromon">
        <img src="https://avatars.githubusercontent.com/u/15263554?v=4"
        width="150px;" alt="rafaelromon"/><br/><sub><b>Rafael Romón</b></sub></a><br/></td>
    <td align="center"><a href="https://github.com/Andychiz">
        <img src="https://avatars.githubusercontent.com/u/74025426?v=4"
        width="150px;" alt="Andychiz"/><br/><sub><b> Chi Zhong</b></sub></a><br/></td>
  </tr>
</table>

<!-- GETTING STARTED -->
## Getting Started

To get a local copy up and running follow these simple steps.

### Prerequisites

Vivado version 2019.2 is advised for synthesis and implementation as some of the IP blocks used in this project may change in newer versions of Vivado.


### Project Installation

1. Clone the repo
   ```sh
   git clone https://github.com/rafaelromon/DAT096-NN1.git
   ```
2. Open Vivado and move into project directory
   ```sh
   cd DAT096-NN1/
   ```
3. Generate the project using the .tcl script
    ```sh
    source ./git_project.tcl
    ```

<!-- USAGE EXAMPLES -->
## Usage

This project is meant to be implemented into a [AC701 Evaluation Kit](https://www.xilinx.com/products/boards-and-kits/ek-a7-ac701-g.html) but other boards may be supported as long as they have the same interfaces.

<!-- CONTRIBUTING -->
## Contributing

This project was developed as part of Chalmers University's DAT096 course during the spring of 2021, as such, there are no plans of further developing this project. Nonetheless, you are more than free to fork this project.


<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE` for more information.

<!-- ACKNOWLEDGEMENTS -->
## Acknowledgements
* [Synective Labs](https://synective.se/) for formulating the project.
* [Chalmers University - DAT096 course](https://student.portal.chalmers.se/en/chalmersstudies/courseinformation/pages/searchcourse.aspx?course_id=26848&parsergrp=3) for supervising the project.


<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[license-shield]: https://img.shields.io/github/license/rafaelromon/repo.svg?style=for-the-badge
[license-url]: https://github.com/rafaelromon/DAT096-NN1/blob/main/LICENSE
