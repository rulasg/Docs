# Rename Docs File

```ps
> dir './Ticket de pago Redsys.pdf' | gdn

Path        : /Users/rulasg/OneDrive/Datos adjuntos de correo electrónico/Ticket de pago Redsys.pdf
NewName     : 260912-rulasg-Ticket_de_pago_Redsys.pdf
Date        : 260912
Owner       : 
Target      : 
What        : 
Amount      : 
Description : Ticket de pago Redsys
Type        : pdf
```

```ps
> dir './Ticket de pago Redsys.pdf' | gdn -Owner karaka -Target CEM -What uniformes -Amount 63#85

Path        : /Users/rulasg/OneDrive/Datos adjuntos de correo electrónico/Ticket de pago Redsys.pdf
NewName     : 260912-karaka-CEM-uniformes-63#85-Ticket_de_pago_Redsys.pdf
Date        : 260912
Owner       : karaka
Target      : CEM
What        : uniformes
Amount      : 63#85
Description : Ticket de pago Redsys
Type        : pdf
```

```ps
> dir './Ticket de pago Redsys.pdf' | gdn -Owner karaka -Target CEM -What uniformes -Amount 63#85 | Rename-DocsFile

> dir *ticket*

    Directory: /Users/rulasg/OneDrive/Datos adjuntos de correo electrónico

UnixMode         User Group         LastWriteTime         Size Name
--------         ---- -----         -------------         ---- ----
-rwx------     rulasg staff      12/09/2026 20:54        24051 260912-karaka-CEM-uniformes-63#85-Ticket_de_pago_Redsys.pdf

```