# Interfaz_Picoblaze-AXI4Lite
Mi Trabajo Fin de Grado.

Consiste en un CORE VHDL sintetizable que permite la conexión entre el microcontrolador Picoblaze y el bus AXI4-Lite, 
así como un entorno de pruebas consistente en un generador de patrones de imagen controlado por UART implementable en una placa Zybo.

El entorno de pruebas se ha creado combinando diversos CORE e IP de Xilinx, junto con un programa en ensamblador (hdmi_program.psm)
para ejecutar en el microcontrolador Picoblaze. La carpeta mi_TPG consiste en un IP personalizado formado por varios COREs que
incluye una entrada de control AXI4-Lite y una salida de video RGB. El CORE se puede ver y modificar desde Vivado.

Por último, el CORE HDMI es el Proyecto Fin de Carrera de Juan David Heredia. Como parte de mis tareas en la beca de colaboración,
depuré el CORE y lo modifiqué para que pudiera usarse a mayor resolución.
