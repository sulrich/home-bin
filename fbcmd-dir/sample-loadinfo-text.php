<?php

//
// If you want to add information to your INFO tab, use this file as a template
//
// try fbcmd LOADINFO sample-loadinfo-text.php
//
// After you use LOADINFO for the first time, you have to visit http://apps.facebook.com/cmdline/ 
// and then click on the 'Add to Info' button
//
// I set up this file becuase there was just too much data to try to send on the command line, 
// and so I figured we might as well use the native way that PHP saves the data.
/// I'm open to alternatives, and if you have a better way of doing this, please contact me.
//
// -Dave [www.dtompkins.com]
//

$fbCmdInfo = array (
  'title' => 'FBCMD Sample Header (Text Mode)',
  'type' => '1',
  'info_fields' => 
  array (
    0 => 
    array (
      'field' => 'Topic One',
      'items' => 
      array (
        0 => 
        array (
          'label' => 'Item One',
          'link' => 'http://www.link.one',
        ),
        1 => 
        array (
          'label' => 'Item Two',
          'link' => 'http://www.link.two',
        ),
      ),
    ),
    1 => 
    array (
      'field' => 'Second Topic',
      'items' => 
      array (
        0 => 
        array (
          'label' => 'Item Three',
          'link' => 'http://www.link.three',
        ),
      ),
    ),
  ),
);
?>
