#!/usr/bin/php
<?php

////////////////////////////////////////////////////////////////////////////////
//     __ _                        _                                          //
//    / _| |                      | |                                         //
//   | |_| |__   ___ _ __ ___   __| |                                         //
//   |  _| '_ \ / __| '_ ` _ \ / _` |                                         //
//   | | | |_) | (__| | | | | | (_| |                                         //
//   |_| |_.__/ \___|_| |_| |_|\__,_|                                         //
//                                                                            //
//   Facebook Command Line Utility                                            //
//   http://www.cs.ubc.ca/~davet/fbcmd                                        //
//   http://www.facebook.com/apps/application.php?id=42463270450              //
//   Copyright (c) 2007,2009 Dave Tompkins [www.dtompkins.com]                //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//  This program is free software: you can redistribute it and/or modify      //
//  it under the terms of the GNU General Public License as published by      //
//  the Free Software Foundation, either version 3 of the License, or         //
//  (at your option) any later version.                                       //
//                                                                            //
//  This program is distributed in the hope that it will be useful,           //
//  but WITHOUT ANY WARRANTY; without even the implied warranty of            //
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             //
//  GNU General Public License for more details.                              //
//                                                                            //
//  You should have received a copy of the GNU General Public License         //
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.     //
//                                                                            //
//  see facebook.php, JSON.php & JSON-LICENSE for additional information      //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//   Having said all that, the author would love you to send him:             //
//   Suggestions,  Modifications and Improvements for re-distribution.        //
//                                                                            //
//   See versions.txt for a list of contributions and a revision history.     //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

  $fbCmdVersion = '0.96';

  $GLOBALS['facebook_config']['debug']=false;

////////////////////////////////////////////////////////////////////////////////

  // These keys identify the application fbcmd to Facebook

  $fbCmdAppKey = 'd96ea311638cf65f04b33c87eacf371e';
  $fbCmdAppSecret = '88af69b7ab8d437bff783328781be79b';

  // This is a generic template for feeds

  $fbFeedTemplate = '60736970450';

////////////////////////////////////////////////////////////////////////////////

  // You can set an environment variable FBCMD to specify the location of
  // your sessionkeys.txt file

  $fbCmdSourceDir = getenv('FBCMD');

  // otherwise, default to c:\fbcmd\ (windows) or ~/fbcmd/ (linux/other)

  if (strtoupper(substr(PHP_OS, 0, 3)) === 'WIN') {
    $cr = "\r\n";
    $isWindows = true;
  } else {
    $cr = "\n";
    $isWindows = false;
  }

  if ($fbCmdSourceDir == '') {
    if ($isWindows) {
      $fbCmdSourceDir = 'c:/fbcmd/';
    } else {
      $fbCmdSourceDir = CleanPath(getenv('HOME')) . 'fbcmd/';
    }
  } else {
    $fbCmdSourceDir = CleanPath($fbCmdSourceDir);
  }

////////////////////////////////////////////////////////////////////////////////

  // include the Facebook API code

  set_include_path (get_include_path() . PATH_SEPARATOR . $fbCmdSourceDir);

  try {
    if(!@include_once('facebookapi_php5_restlib.php')) throw new Exception('');
    if(!@include_once('facebook.php')) throw new Exception('');
    if(!@include_once('facebook_desktop.php')) throw new Exception('');
  } catch(Exception $e) {
    FbCmdFatalError('Missing Facebook API files: can\'t find facebook*.php in ' . get_include_path());
  }

////////////////////////////////////////////////////////////////////////////////

  // fbcmd RESET will create a blank sessionkeys.txt file

  if ($argc == 2) {
    if (strtoupper($argv[1]) == 'RESET') {
      if (file_put_contents("{$fbCmdSourceDir}sessionkeys.txt","EMPTY\nEMPTY\n# only the first two lines of this file are read\n# use fbcmd RESET to replace this file\n")==false) {
        FbCmdFatalError("Could not generate {$fbCmdSourceDir}sessionkeys.txt");
      }
    }
    if (strtoupper($argv[1]) == 'AUTH') {
      FbCmdFatalError("AUTH requires a 2nd CODE parameter: obtain a code here:\n\nhttp://www.facebook.com/code_gen.php?v=1.0&api_key={$fbCmdAppKey}\n\n or http://tinyurl.com/fbcmd-auth");
    }
  }

////////////////////////////////////////////////////////////////////////////////

  // fbcmd AUTH will generate a new sessionkeys.txt file

  if ($argc == 3) {
    if (strtoupper($argv[1]) == 'AUTH') {
      try {
        $fbObject = new FacebookDesktop($fbCmdAppKey, $fbCmdAppSecret);
        $session = $fbObject->do_get_session($argv[2]);
      } catch (Exception $e) {
        FbCmdException('Invalid AUTH code / could not authorize session',$e);
      }
      $fbCmdUserSessionKey = $session['session_key'];
      $fbCmdUserSecretKey = $session['secret'];
      if (file_put_contents ("{$fbCmdSourceDir}sessionkeys.txt","{$fbCmdUserSessionKey}\n{$fbCmdUserSecretKey}\n# only the first two lines of this file are read\n# use fbcmd RESET to replace this file\n")==false) {
        FbCmdFatalError("Could not generate {$fbCmdSourceDir}sessionkeys.txt");
      }
      try {
        $fbObject->api_client->session_key = $fbCmdUserSessionKey;
        $fbObject->secret = $fbCmdUserSecretKey;
        $fbObject->api_client->secret = $fbCmdUserSecretKey;
        $fbUser = $fbObject->api_client->call_method('facebook.users.getLoggedInUser', array());
        $fbReturn = $fbObject->api_client->users_getInfo($fbUser,array('first_name','last_name'));
      } catch (Exception $e) {
        FbCmdException('Invalid AUTH code / could not generate session key',$e);
      }
      print "\nfbcmd [v$fbCmdVersion] Facebook Command Line by Dave Tompkins\n\n";
      print "Welcome {$fbReturn[0]['first_name']} {$fbReturn[0]['last_name']} -- You have been properly AUTHORIZED!\n\n";
      exit;
    }
  }

////////////////////////////////////////////////////////////////////////////////

  // attempt to read in the sessionkeys.txt file

  if (!file_exists("{$fbCmdSourceDir}sessionkeys.txt")) {
    FbCmdFatalError("Could not locate {$fbCmdSourceDir}sessionkeys.txt");
  }
  $fbCmdKeyFile = file("{$fbCmdSourceDir}sessionkeys.txt",FILE_IGNORE_NEW_LINES);
  if (count($fbCmdKeyFile) < 2) {
    FbCmdFatalError("Invalid {$fbCmdSourceDir}sessionkeys.txt file");
  }
  $fbCmdUserSessionKey = $fbCmdKeyFile[0];
  $fbCmdUserSecretKey = $fbCmdKeyFile[1];

  if (strncmp($fbCmdUserSessionKey,'EMPTY',5)==0) {
    print "\n";
    print "fbcmd [v{$fbCmdVersion}] Facebook Command Line by Dave Tompkins\n\n";
    print "Welcome to fbcmd.  To use this applicaiton, you need to obtain a\n";
    print "facebook authorization code which can be obtained here:\n\n";
    print "http://www.facebook.com/code_gen.php?v=1.0&api_key={$fbCmdAppKey}\n\n";
    print "or http://tinyurl.com/fbcmd-auth\n\n";
    print "obtain your 6-digit code, and then execute fbcmd AUTH XXXXXX\n\n";
    exit;
  }

////////////////////////////////////////////////////////////////////////////////

  // create the Facebook Object

  try {
    $fbObject = new FacebookDesktop($fbCmdAppKey, $fbCmdAppSecret);
    $fbObject->api_client->session_key = $fbCmdUserSessionKey;
    $fbObject->secret = $fbCmdUserSecretKey;
    $fbObject->api_client->secret = $fbCmdUserSecretKey;
    $fbUser = $fbObject->api_client->call_method('facebook.users.getLoggedInUser', array());
  } catch (Exception $e) {
    FbCmdException('Could not use session key / log in user',$e);
  }

////////////////////////////////////////////////////////////////////////////////

  if ($argc == 1) {
    FbCMDUsage();
  }
  $fbCommand = strtoupper($argv[1]);

////////////////////////////////////////////////////////////////////////////////

  // depricated commands:

  if ($fbCommand == 'FEED') {
    FbCmdFatalError("FEED has been depricated. Use:\n                     FEED1 (one line) or FEED2 (short) or FEED3 (full)\n");
  }

  if ($fbCommand == 'FSTATUSID') {
    print "**Warning: FSTATUSID has been depricated: using FSTATUS \n";
    $fbCommand = 'FSTATUS';
  }

  if ($fbCommand == 'FLSTATUS') {
    FbCmdFatalError("FLSTATUS has been depricated. Use:\n                     FSTATUS with a leading underscore (_)\n                     so FLSTATUSID mylist is now FSTATUS _mylist\n");
  }

  if ($fbCommand == 'DFILE') {
    print "**Warning: DFILE has been depricated: using LOADDISP \n";
    $fbCommand = 'LOADDISP';
  }

////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'ADDALBUM') {
    CheckParameters(1,4);
    if ($argc >= 4) {
      $description = $argv[3];
    } else {
      $description = '';
    }
    if ($argc >= 5) {
      $location = $argv[4];
    } else {
      $location = '';
    }
    if ($argc == 6) {
      $visible = $argv[5];
      if (!in_array($visible,array('friends','friends-of-friends','networks','everyone'))) {
        FbCmdFatalError("ADDALBUM 4th parameter must be one of:\n                     friends,friends-of-friends,networks,everyone");
      }
    } else {
      $visible = 'everyone';
    }
    try {
      $fbReturn = $fbObject->api_client->photos_createAlbum($argv[2],$description,$location,$visible);
    } catch (Exception $e) {
      FbCmdException('ADDALBUM',$e);
    }
    if (!empty($fbReturn)) {
      print $fbReturn['aid'] . ' ' . $fbReturn['link'] . "\n";
    }
    exit;
  }

////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'ADDPIC') {
    CheckParameters(1,3);
    if ($argc == 5) {
      $caption = $argv[4];
    } else {
      $caption = '';
    }
    if ($argc >= 4) {
      $aid = $argv[3];
    } else {
      $aid = null;
    }
    try {
      $fbReturn = $fbObject->api_client->photos_upload($argv[2], $aid, $caption, $fbUser);
    } catch (Exception $e) {
      FbCmdException('ADDPIC',$e);
    }
    if (!empty($fbReturn)) {
      print $fbReturn['pid'] . ' ' . $fbReturn['link'] . "\n";
    }
    exit;
  }

////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'ALBUMS') {
    CheckParameters(0);
    try {
      $albumlist = $fbObject->api_client->photos_getAlbums($fbUser,null);
    } catch (Exception $e) {
      FbCmdException('ALBUMS',$e);
    }
    if (!empty($albumlist)) {
      foreach ($albumlist as $album) {
        print $album['aid'] . ' ' . $album['name'] . ' (' . $album['size'] . ' photos)' . "\n";
      }
    }
    exit;
  }

////////////////////////////////////////////////////////////////////////////////

  $allUserInfoFields = "about_me,activities,affiliations,birthday,books,current_location,education_history,email_hashes,first_name,has_added_app,hometown_location,hs_info,interests,is_app_user,last_name,locale,meeting_for,meeting_sex,movies,music,name,notes_count,pic,pic_big,pic_big_with_logo,pic_small,pic_small_with_logo,pic_square,pic_square_with_logo,pic_with_logo,political,profile_update_time,profile_url,proxied_email,quotes,relationship_status,religion,sex,significant_other_id,status,timezone,tv,uid,wall_count,work_history";

  if ($fbCommand == 'ALLINFO') {
    CheckParameters(1);
    $userQuery = FbGetUserQuery($argv[2]);
    $fql = "SELECT {$allUserInfoFields} from user where uid in ({$userQuery}) ORDER BY last_name";
    try {
      $fbReturn = $fbObject->api_client->fql_query($fql);
    } catch(Exception $e) {
      FbCmdException('ALLINFO',$e);
    }
    if (!empty($fbReturn)) {
      foreach ($fbReturn as $user) {
        print DisplayId($user) . DisplayName($user). " " . print_r($user,true) . "\n";
      }
    }
    exit;
  }

////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'DISPLAY') {
    CheckParameters(1);
    try {
      $fbObject->api_client->profile_setFBML($argv[2],null,$argv[2],'',$argv[2],$argv[2]);
    } catch (Exception $e) {
      FbCmdException('DISPLAY',$e);
    }
    exit;
  }

////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'EVENTS') {
    CheckParameters(0);
    try {
      $fbReturn = $fbObject->api_client->events_get($fbUser,null,time(),null,null);
    } catch (Exception $e) {
      FbCmdException('EVENTS',$e);
    }
    if (!empty($fbReturn)) {
      usort($fbReturn,'CmpEventDate');
      foreach ($fbReturn as $event) {
        print date('D M d h:i',$event['start_time']) . ' ' . $event['name'] . "\n";
      }
    }
    exit;
  }

////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'FEED1') {
    CheckParameters(1);
    try {
      $fbObject->api_client->feed_publishUserAction($fbFeedTemplate,array('title-text' => $argv[2], 'body-text' => ''),'','',FacebookRestClient::STORY_SIZE_ONE_LINE);
    } catch (Exception $e) {
      FbCmdException('FEED1',$e);
    }
    exit;
  }

////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'FEED2') {
    if (($argc != 4)&&($argc != 6)) {
      CheckParameters(2);
    }
    if ($argc == 4) {
      try {
        $fbObject->api_client->feed_publishUserAction($fbFeedTemplate,array('title-text' => $argv[2], 'body-text' => $argv[3]),'','',FacebookRestClient::STORY_SIZE_SHORT);
      } catch (Exception $e) {
        FbCmdException('FEED2',$e);
      }
    }
    if ($argc == 6) {
      try {
        $fbObject->api_client->feed_publishUserAction($fbFeedTemplate,array('title-text' => $argv[2], 'body-text' => $argv[3], 'images' => array( array('src' => $argv[4], 'href' => $argv[5]))),'','',FacebookRestClient::STORY_SIZE_SHORT);
      } catch (Exception $e) {
        FbCmdException('FEED2',$e);
      }
    }
    exit;
  }

////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'FEED3') {
    CheckParameters(2);
    try {
      $fbObject->api_client->feed_publishUserAction($fbFeedTemplate,array('title-text' => $argv[2], 'body-text' => $argv[3]),'','',FacebookRestClient::STORY_SIZE_FULL);
    } catch (Exception $e) {
      FbCmdException('FEED3',$e);
    }
    exit;
  }

////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'FEEDLINK') {
    CheckParameters(1,2);
    if ($argc == 4) {
      $comment = $argv[3];
    } else {
      $comment = '';
    }
    try {
      $fbObject->api_client->links_post($argv[2],$comment);
    } catch (Exception $e) {
      if ($e->getCode() == 282) {
        FbCmdFatalError("FEEDLINK requires special permissions:\n\nvisit the website:\n\nhttp://www.facebook.com/authorize.php?api_key={$fbCmdAppKey}&v=1.0&ext_perm=share_item\n\nor http://tinyurl.com/fbcmd-feedlink\n\nto grant permissions\n");
      } else {
        FbCmdException('FEEDLINK',$e);
      }
    }
    exit;
  }

////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'FEEDNOTE') {
    CheckParameters(2);
    try {
      $fbObject->api_client->notes_create($argv[2],$argv[3]);
    } catch (Exception $e) {
      if ($e->getCode() == 281) {
        FbCmdFatalError("FEEDNOTE requires special permissions:\n\nvisit the website:\n\nhttp://www.facebook.com/authorize.php?api_key={$fbCmdAppKey}&v=1.0&ext_perm=create_note\n\nor http://tinyurl.com/fbcmd-feednote\n\nto grant permissions\n");
      } else {
        FbCmdException('FEEDNOTE',$e);
      }
    }
    exit;
  }

////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'FINFO') {
    CheckParameters(1,2);
    if ($argc == 3) {
      $userQuery = "SELECT uid2 FROM friend WHERE uid1={$fbUser} AND uid2=uid2";
    } else {
      $userQuery = FbGetUserQuery($argv[3]);
    }
    $fql = "SELECT uid,first_name,last_name,{$argv[2]} from user where uid in ({$userQuery}) ORDER BY last_name";
    try {
      $fbReturn = $fbObject->api_client->fql_query($fql);
    } catch(Exception $e) {
      if ($e->getCode() == 602) {
        FbCmdFatalError("FINFO: invalid field: {$e->getMessage()}");
      } else {
        FbCmdException('FINFO',$e);
      }
    }
    if (!empty($fbReturn)) {
      foreach ($fbReturn as $user) {
        $fieldData = $user[$argv[2]];
        if ($fieldData != '') {
          if (gettype($fieldData) == 'array') {
            $fieldData = print_r($fieldData,true);
          } else {
            $fieldData = str_replace(array("\n","\r"),'<br>',$fieldData);
          }
          print DisplayId($user) . DisplayName($user). " {$fieldData}\n";
        }
      }
    }
    exit;
  }


////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'FLAST') {
    CheckParameters(1,2);
    if ($argc == 4) {
      $fcount = $argv[3];
    } else {
      $fcount = 10;
    }
    $matches = FbGetFriendList($argv[2]);
    foreach ($matches as $user) {
      try {
        $fbReturn = $fbObject->api_client->fql_query("SELECT message FROM status WHERE uid={$user['uid']} LIMIT {$fcount}");
      } catch (Exception $e) {
        FbCmdException('FLAST',$e);
      }
      if (empty($fbReturn)) {
        print DisplayName($user) . "[n/a]\n\n";
      } else {
        foreach ($fbReturn as $status) {
          print DisplayName($user) . $status['message'] . "\n";
        }
        print "\n";
      }
    }
    exit;
  }

////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'FONLINE') {
    CheckParameters(0,1);
    if ($argc == 2) {
      $userQuery = "SELECT uid2 FROM friend WHERE uid1={$fbUser} AND uid2=uid2";
    } else {
      $userQuery = FbGetUserQuery($argv[2]);
    }
    $fql = "SELECT first_name,last_name,online_presence from user where uid in ({$userQuery}) and online_presence != 'offline' ORDER BY last_name";
    try {
      $fbReturn = $fbObject->api_client->fql_query($fql);
    } catch (Exception $e) {
      FbCmdException('FONLINE',$e);
    }
    if (!empty($fbReturn)) {
      foreach ($fbReturn as $user) {
        print DisplayName($user) . " [{$user['online_presence']}]\n";
      }
    }
    exit;
  }

////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'FPICS') {
    CheckParameters(1,2);
    if ($argc == 3) {
      $save = false;
    } else {
      $save = true;
      $savePath = CleanPath($argv[3]);
      if (!file_exists($savePath)) {
        FbCmdFatalError("Invalid Path: $savePath");
      }
    }
    $matches = FbGetFriendList($argv[2]);
    foreach ($matches as $user) {
      try {
        $photoList = $fbObject->api_client->photos_get($user['uid'],null,null);
      } catch (Exception $e) {
        FbCmdException('FPICS-GET',$e);
      }
      if (empty($photoList)) {
        print DisplayName($user) . "(0 Photos)\n\n";
      } else {
        print DisplayName($user) . "(" . count($photoList) ." Photos)\n\n";
        foreach ($photoList as $photo) {
          print $photo['pid'] . ' ' . $photo['src_big'] . "\n";
          if ($save) {
            GetSavePhoto($photo['src_big'],$savePath . $photo['pid'] . '.jpg');
          }
        }
        print "\n";
      }
    }
    exit;
  }

////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'FRIENDS') {
    CheckParameters(0);
    try {
      $fbFriends = $fbObject->api_client->friends_get();
      $fbReturn = $fbObject->api_client->users_getInfo($fbFriends,array('uid','first_name','last_name'));
    } catch (Exception $e) {
      FbCmdException('FRIENDS',$e);
    }
    if (!empty($fbReturn)) {
      foreach ($fbReturn as $user) {
        print DisplayId($user) . DisplayName($user) . "\n";
      }
    }
    exit;
  }

////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'FSTATUS') {
    CheckParameters(0,1);
    if ($argc == 2) {
      $matches = FbGetFriendList('=ALL');
    } else {
      $matches = FbGetFriendList($argv[2]);
    }
    foreach ($matches as $user) {
      if (empty($user['status'])) {
        $s = '[n/a]';
      } else {
        if ($user['status']['message']=='') {
          $s = '[blank]';
        } else {
          $s = $user['status']['message'];
        }
      }
      print DisplayName($user) . " $s\n";
    }
    exit;
  }

////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'LIMITS') {
    CheckParameters(0);
    try {
      print "\n";
      print "Maximum FEED     commands per day:  10\n"; // -sigh- hard coded for now
      print "Maximum NSEND    commands per day:  " . $fbObject->api_client->admin_getAllocation('notifications_per_day'). "\n";
      //print "Maximum          requests per day:  " . $fbObject->api_client->admin_getAllocation('requests_per_day'). " (it's unclear what a request is)\n";
    } catch (Exception $e) {
      FbCmdException('LIMITS',$e);
    }
    exit;
  }

////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'LOADDISP') {
    CheckParameters(1);
    if (!file_exists($argv[2])) {
      FbCmdFatalError("Could not locate file {$argv[2]}");
    }
    $fbFbmlFile = file_get_contents($argv[2]);
    if ($fbFbmlFile == false) {
      FbCmdFatalError("Could not read file {$argv[2]}");
    } else {
      try {
        $fbObject->api_client->profile_setFBML($fbFbmlFile,null,$fbFbmlFile,'',$fbFbmlFile,$fbFbmlFile);
      } catch (Exception $e) {
        FbCmdException('LOADDISP',$e);
      }
    }
    exit;
  }

  ////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'LOADINFO') {
    CheckParameters(1);
    if (!file_exists($argv[2])) {
      FbCmdError("Could not locate file {$argv[2]}");
    }
    $fbCmdInfo = '';
    try {
      if(!@include_once($argv[2])) throw new Exception('');
    } catch(Exception $e) {
      FbCmdError("Could not read Info File {$argv[2]}");
    }
    if ($fbCmdInfo == '') {
      FbCmdError("\$fbCmdInfo was not set properly in {$argv[2]}");
    }
    try {
      $fbObject->api_client->profile_setInfo($fbCmdInfo['title'], $fbCmdInfo['type'], $fbCmdInfo['info_fields']);
    } catch (Exception $e) {
      FbCmdException('LOADINFO',$e);
    }
    exit;
  }

////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'LOADNOTE') {
    CheckParameters(2);
    if (!file_exists($argv[3])) {
      FbCmdFatalError("Could not locate file {$argv[2]}");
    }
    $fbFbmlFile = file_get_contents($argv[3]);
    if ($fbFbmlFile == false) {
      FbCmdFatalError("Could not read file {$argv[3]}");
    } else {
      try {
        $fbObject->api_client->notes_create($argv[2],$fbFbmlFile);
      } catch (Exception $e) {
        if ($e->getCode() == 281) {
          FbCmdFatalError("LOADNOTE requires special permissions:\n\nvisit the website:\n\nhttp://www.facebook.com/authorize.php?api_key={$fbCmdAppKey}&v=1.0&ext_perm=create_note\n\nor http://tinyurl.com/fbcmd-feednote\n\nto grant permissions\n");
        } else {
          FbCmdException('LOADNOTE',$e);
        }
      }
    }
    exit;
  }

  ////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'NOTIFY') {
    CheckParameters(0);
    try {
      $fbNotifications = $fbObject->api_client->notifications_get();
      print "{$fbNotifications['messages']['unread']} unread messages\n";
      print "{$fbNotifications['pokes']['unread']} pokes\n";
      print "{$fbNotifications['shares']['unread']} shares\n";

      if (empty($fbNotifications['friend_requests'])) {
        print "0 friend requests\n";
      } else {
        $fbReturn = $fbObject->api_client->users_getInfo($fbNotifications['friend_requests'],array('first_name','last_name'));
        print count($fbReturn) . " friend requests\n";
        foreach ($fbReturn as $user) {
          print "  * {$user['first_name']} {$user['last_name']}\n";
        }
      }

      if (empty($fbNotifications['group_invites'])) {
        print "0 group invites\n";
      } else {
        $fbReturn = $fbObject->api_client->call_method('facebook.groups.get', array('gids' => $fbNotifications['group_invites']));
        print count($fbReturn) . " group invites\n";
        foreach ($fbReturn as $group) {
          print "  * {$group['name']}\n";
        }
      }

      if (empty($fbNotifications['event_invites'])) {
        print "0 event invites\n";
      } else {
        $fbReturn = $fbObject->api_client->call_method('facebook.events.get', array('eids' => $fbNotifications['event_invites']));
        print count($fbReturn) . " event invites\n";
        foreach ($fbReturn as $events) {
          print "  * {$events['name']}\n";
        }
      }
    } catch (Exception $e) {
      FbCmdException('NOTIFY',$e);
    }
    exit;
  }

////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'NSEND') {
    CheckParameters(2);
    $matches = FbGetFriendList($argv[2],false,false);
    if (count($matches)==0) {
      FbCmdFatalError("NSEND requires an exact match: No match for '{$argv[2]}'");
    }
    foreach ($matches as $user) {
      try {
        $fbObject->api_client->notifications_send($user['uid'], $argv[3], 'user_to_user');
        print "Message sent to : " . DisplayName($user) . "\n";
      } catch (Exception $e) {
        FbCmdException('FONLINE',$e);
      }
    }
    exit;
  }

////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'PICS') {
    CheckParameters(0,1);
    if ($argc == 2) {
      $save = false;
    } else {
      $save = true;
      $savePath = CleanPath($argv[2]);
      if (!file_exists($savePath)) {
        FbCmdFatalError("Invalid Path: $savePath");
      }
    }
    try {
      $albumlist = $fbObject->api_client->photos_getAlbums($fbUser,null);
    } catch (Exception $e) {
      FbCmdException('PICS-ALBUMS',$e);
    }
    if (!empty($albumlist)) {
      foreach ($albumlist as $album) {
        print 'ALBUM: ' . $album['aid'] . ' ' . $album['name'] . ' (' . $album['size'] . ' photos)' . "\n\n";
        try {
          $fbReturn = $fbObject->api_client->photos_get(null,$album['aid'],null);
        } catch (Exception $e) {
          FbCmdException('PICS-GET',$e);
        }
        if (!empty($fbReturn)) {
          foreach ($fbReturn as $photo) {
            print $photo['pid'] . ' ' . $photo['src_big'] . "\n";
            if ($save) {
              GetSavePhoto($photo['src_big'],$savePath . $photo['pid'] . '.jpg');
            }
          }
          print "\n";
        }
      }
    }
    exit;
  }

////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'PPICS') {
    CheckParameters(0,2);
    if ($argc < 4) {
      $save = false;
    } else {
      $save = true;
      $savePath = CleanPath($argv[3]);
      if (!file_exists($savePath)) {
        FbCmdFatalError("Invalid Path: $savePath");
      }
    }
    if ($argc < 3) {
      $userQuery = "SELECT uid2 FROM friend WHERE uid1={$fbUser} AND uid2=uid2";
    } else {
      $userQuery = FbGetUserQuery($argv[2]);
    }
    $fql = "SELECT uid,first_name,last_name,pic_big from user where uid in ({$userQuery}) ORDER BY last_name";
    try {
      $fbReturn = $fbObject->api_client->fql_query($fql);
    } catch(Exception $e) {
      FbCmdException('PPICS',$e);
    }
    if (!empty($fbReturn)) {
      foreach ($fbReturn as $user) {
        $picURL = $user['pic_big'];
        if ($picURL != '') {
          print DisplayId($user) . DisplayName($user). $picURL . "\n";
          if ($save) {
            GetSavePhoto($picURL,$savePath . $user['uid'] . '.jpg');
          }
        }
      }
    }
    exit;
  }

////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'RECENT') {
    CheckParameters(0,1);
    if ($argc == 2) {
      $fcount = 20;
    } else {
      $fcount = $argv[2];
    }
    $fql = "SELECT first_name,last_name,status.message from user where uid in (SELECT uid2 FROM friend WHERE uid1={$fbUser} AND uid2=uid2) and status.message != '' ORDER BY status.time DESC LIMIT {$fcount}";
    try {
      $fbReturn = $fbObject->api_client->fql_query($fql);
    } catch (Exception $e) {
      FbCmdException('RECENT',$e);
    }
    if (!empty($fbReturn)) {
      foreach ($fbReturn as $user) {
        print DisplayName($user) . " {$user['status']['message']} \n\n";
      }
    }
    exit;
  }

////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'SAVEDISP') {
    CheckParameters(1);
    try {
      $fbFbml = $fbObject->api_client->profile_getFBML($fbUser,2);
    } catch (Exception $e) {
      FbCmdException('SAVEINFO',$e);
    }
    // strip out the <fb:fbml> header
    $fbFbml = preg_replace('/<fb:fbml version="\d.\d">/','',$fbFbml);
    $fbFbml = preg_replace('/<\/fb:fbml>/','',$fbFbml);
    if (file_put_contents($argv[2],$fbFbml) == false) {
      FbCmdFatalError("Could not write file {$argv[2]}");
    }
    exit;
  }

////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'SAVEINFO') {
    CheckParameters(1);
    try {
      $fbInfoObject = $fbObject->api_client->profile_getInfo();
    } catch (Exception $e) {
      FbCmdException('SAVEINFO',$e);
    }
    $fbInfoFile = var_export($fbInfoObject,true);
    $fbInfoFile = "<?php\n\$fbCmdInfo = {$fbInfoFile};\n?>\n";
    if (file_put_contents($argv[2],$fbInfoFile) == false) {
      FbCmdFatalError("Could not write file {$argv[2]}");
    }
    exit;
  }

////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'STATUS') {
    CheckParameters(0,1);
    if ($argc == 2) {
      try {
        $fbReturn = $fbObject->api_client->users_getInfo($fbUser,array('first_name','status'));
      } catch (Exception $e) {
        FbCmdException('GETSTATUS',$e);
      }
      print "{$fbReturn[0]['first_name']} {$fbReturn[0]['status']['message']}\n";
    } else {
      try {
        $fbObject->api_client->call_method('facebook.users.setStatus',array('status' => $argv[2],'status_includes_verb' => true));
      } catch(Exception $e) {
        if ($e->getCode() == 250) {
          FbCmdFatalError("STATUS requires special permissions:\n\nvisit the website:\n\nhttp://www.facebook.com/authorize.php?api_key={$fbCmdAppKey}&v=1.0&ext_perm=status_update\n\nor http://tinyurl.com/fbcmd-status\n\nto grant permissions\n");
        } else {
          FbCmdException('STATUS',$e);
        }
      }
    }
    exit;
  }

////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'TAGPIC') {
    if (($argc != 4)&&($argc != 6)) {
      CheckParameters(2);
    }
    if ($argc == 6) {
      $x = $argv[4];
      $y = $argv[5];
    } else {
      $x = 50;
      $y = 50;
    }
    try {
      if (strtoupper($argv[3]) == '=ME') {
        $fbObject->api_client->photos_addTag($argv[2],$fbUser,null,$x,$y,null,null);
      } else {
        if (is_numeric($argv[3])) {
          $fbObject->api_client->photos_addTag($argv[2],$argv[3],null,$x,$y,null,null);
        } else {
          // check for a an exact user name match
          $matchStringUC = strtoupper($argv[3]);
          $matches = FbGetFriendList('=ALL');
          foreach ($matches as $user) {
            if (strtoupper(trim($user['first_name'] . " " . $user['last_name'])) == $matchStringUC) {
              $fbObject->api_client->photos_addTag($argv[2],$user['uid'],null,$x,$y,null,null);
              exit;
            }
          }
          // no match... put in as text tag
          $fbObject->api_client->photos_addTag($argv[2],null,$argv[3],$x,$y,null,null);
        }
      }
    } catch (Exception $e) {
      FbCmdException('TAGPIC',$e);
    }
    if (!empty($fbReturn)) {
      print $fbReturn . "\n";
    }
    exit;
  }

////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'UFIELDS') {
    print "\n";
    print "Available user fields for FINFO: \n";
    print "(see http://wiki.developers.facebook.com/index.php/Users.getInfo)\n\n";
    $uFields = explode(',',$allUserInfoFields);
    foreach ($uFields as $u) {
      print "  * {$u}\n";
    }
    print "\n";
    exit;
  }


////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'USAGE') {
    FbCMDUsage();
  }

////////////////////////////////////////////////////////////////////////////////

  if ($fbCommand == 'VERSION') {
    CheckParameters(0);
    try {
      $fbOnlineVersion = file_get_contents('http://www.cs.ubc.ca/~davet/fbcmd/curversion.txt');
    } catch (Exception $e) {
      FbCmdFatalError('Could not connect to http://www.cs.ubc.ca/~davet/fbcmd/');
    }
    print "CURRENT VERSION: {$fbCmdVersion}\n";
    print "ONLINE VERSION:  {$fbOnlineVersion}\n";
    if ($fbCmdVersion != $fbOnlineVersion) {
      print "\ndownload the latest version from http://www.cs.ubc.ca/~davet/fbcmd/\n";
    } else {
      print "\nyou are up-to-date!\n";
    }
    exit;
  }

////////////////////////////////////////////////////////////////////////////////


  FbCmdFatalError("Unknown Command: [{$fbCommand}] try fbcmd USAGE");
  exit;

  function FbCMDUsage() {
    global $fbCmdVersion;
    global $fbCmdAppKey;

    print "\n";
    print "fbcmd [v{$fbCmdVersion}] Facebook Command Line by Dave Tompkins\n\n";

    print "usage:\n\n";

    print "  fbcmd COMMAND required_parameter(s) [optional_parameter(s)]\n\n";

    print "example:\n\n";

    print "  fbcmd status \"is excited to play with fbcmd\"\n\n";

    print "commands: (can be in lower case)\n\n";

    print "  ADDALBUM txt [txt] [txt] [p] create new photo album: (1) title [2] descript. \n";
    print "                               [3] location [4] privacy: one of: (* = default) \n";
    print "                               friends,friends-of-friends,networks,everyone*   \n\n";

    print "  ADDPIC   file [aid] [txtH]   upload (add) photo. (1) file.jpg (or .gif, etc) \n";
    print "                               [2] album ID (see ALBUMS) [3] caption           \n";
    print "                               tinyurl.com/fbcmd-addpic to avoid 'approvals'   \n\n";

    print "  ALBUMS                       list all your photo album IDs & descriptions    \n\n";

    print "  ALLINFO  flist               get all user information on friend(s) in flist  \n\n";

    print "  AUTH     code                sets your facebook authorization code           \n";
    print "                               (do only once: see website for details)         \n\n";

    print "  DISPLAY  fbml                set the content of your fbcmd profile box       \n";
    print "                               (see website for detials on authorizing this)   \n\n";

    print "  EVENTS                       display upcoming events                         \n\n";

    print "  FEED1    txtA                add a one-line story to your wall feed          \n\n";

    print "  FEED2    txtA txtB [url url] add a short story to your wall feed. (1) title  \n";
    print "                               (2) detail [3] img url [4] click to url         \n\n";

    print "  FEED3    txtA fbml           add a long story to wall. (1) title (2) story   \n\n";

    print "  FEEDLINK url [txtH]          add a link to wall feed (1) url [2] comment     \n\n";

    print "  FEEDNOTE txt txtF            add a note to wall feed (1) title (2) detail    \n\n";

    print "  FINFO    field [flist]       get specific information on friend(s) in flist  \n";
    print "                               (1) field (see UFIELDS) [2] flist               \n\n";

    print "  FLAST    flist [n]           Displays the last n status updates of friends   \n";
    print "                               [2] # of updates per friend [default=10]        \n\n";

    print "  FONLINE  [flist]             list any friends who are currently online       \n\n";

    print "  FPICS    flist [savepath]    list all pictures where friend(s) are tagged    \n\n";

    print "  FRIENDS                      generate a list of all your friends & id's      \n\n";

    print "  FSTATUS  [flist]             get current status of friend(s) in flist        \n\n";

    print "  LIMITS                       display current limits on usage (eg: on NSEND)  \n\n";

    print "  LOADDISP file.fbml           same as DISPLAY, but loads content from file    \n\n";

    print "  LOADINFO file.php            sets the content of your fbcmd info tab.        \n";
    print "                               (see sample-loadinfo-text.php for more details) \n\n";

    print "  LOADNOTE txt file.txtF       same as FEEDNOTE, but [2] detail is from a file \n\n";

    print "  NOTIFY                       see (simple) notifications: # unread msgs, etc. \n\n";

    print "  NSEND    flist txtN          send a notification to friends                  \n";
    print "                               (requires exact matches in flist to avoid spam) \n\n";

    print "  PICS     [savepath]          list all of the pictures in all your albums     \n\n";

    print "  PPICS    [flist] [savepath]  list profile pictures of friend(s) [in flist]   \n\n";

    print "  RECENT   [n]                 shows [n] most recent friend updates            \n\n";

    print "  RESET                        resets any authorization codes set by AUTH      \n\n";

    print "  SAVEDISP file.fbml           saves content of your fbcmd profile box         \n\n";

    print "  SAVEINFO file.php            saves content of your fbcmd info tab            \n\n";

    print "  STATUS   [txtH]              no parameter: display your current status       \n";
    print "                               [1] sets your current status                    \n\n";

    print "  TAGPIC   picid taginf [x y]  tag photo: (1) picture id (2) see taginf below  \n";
    print "                               [3 4] relative x y co-ord: (50 50 is default)   \n";
    print "                               0 0 is upper left and 100 100 is bottom right   \n\n";

    print "  UFIELDS                      display the available fields for FINFO          \n\n";

    print "  USAGE                        displays this message                           \n\n";

    print "  VERSION                      check to see the latest version available       \n\n";

    print "parameter details:\n\n";
    print "  fbml      facebook's html: supports many html tags and extra <fb:> tags      \n\n";

    print "  flist     a comma separated list of friends to match: can be in many forms:  \n";
    print "              1) a facebook user ID (eg: 21008544)                             \n";
    print "              2) a friend list: prefix with an underscore (eg: _mylist)        \n";
    print "              3) an exact match (eg: \"Bob Smith\") or partial match (eg: bob)   \n";
    print "              4) a regular expression (eg: ^(R|B)ob\sS.*h$                     \n";
    print "              5) special keywords: =me, =all, =online, =bday (today's)         \n";
    print "            they can be combined: (eg: \"21008544,_mylist,bob,=me\")             \n\n";

    print "  savepath  when specified, downloads the listed photos to a specified path    \n\n";

    print "  taginfo   can be in one of 4 forms:                                          \n";
    print "              1) a facebook user ID (eg: 21008544)                             \n";
    print "              2) special keyword: =me                                          \n";
    print "              3) an exact match (eg: \"Bob Smith\")                              \n";
    print "              4) any text                                                      \n\n";

    print "  txt       basic text: some commands allow some special codes:                \n";
    print "              <b> : bold              <i>  : italic            <img> : images  \n";
    print "              cr  : carraige returns  <br> : html line breaks                  \n";
    print "              <a> : hyperlinks        http : will convert http text to a link  \n\n";

    print "  txtA      supports <a>                                                       \n";
    print "  txtB      supports <b>,<i>,<br>,<a>                                          \n";
    print "  txtF      supports <b>,<i>,<img>,cr,<br>,<a>                                 \n";
    print "  txtH      supports http                                                      \n";
    print "  txtN      supports <b>,<i>,<a>                                               \n\n";


    print "for additional help and resources:\n\n";

    print "  http://www.cs.ubc.ca/~davet/fbcmd/\n";
    print "  http://www.facebook.com/apps/application.php?id=42463270450\n\n";
    exit;
  }

////////////////////////////////////////////////////////////////////////////////

  function FbCmdFatalError($err) {
    global $fbCmdVersion;
    print "\nfbcmd [v{$fbCmdVersion}] ERROR: {$err}\n";
    exit;
  }

  function FbCmdException($cmd,Exception $e) {
    FbCmdFatalError("{$cmd}\n[{$e->getCode()}] {$e->getMessage()}");
  }

////////////////////////////////////////////////////////////////////////////////

  function FbGetFriendList($listString, $allowRegEx = true, $failOnEmpty = true) {

    global $fbObject;
    global $fbFriendIds;
    global $fbFriends;
    global $fbFriendListIds;
    global $friendGetFields;

    $friendGetFields = array('uid','first_name','last_name','status.message');

    try {
      $fbFriendIds = $fbObject->api_client->friends_get();
      $fbFriends = $fbObject->api_client->users_getInfo($fbFriendIds,$friendGetFields);
      $fbFriendListIds = $fbObject->api_client->friends_getLists();
    } catch (Exception $e) {
      FbCmdException('GetFriendList',$e);
    }

    if (strpos($listString,',')==false) {
      $friendList = FbMatchUser($listString, $allowRegEx);
    } else {
      $friendList = array();
      $listMatches = explode(",",$listString);
      foreach ($listMatches as $match) {
        $found = FbMatchUser($match,$allowRegEx);
        if (count($found)==0) {
          print "**Warning: No Match on {$match}\n";
        } else {
          $friendList = array_merge($friendList,$found);
        }
      }
    }
    if (($failOnEmpty)&&(count($friendList)==0)) {
      FbCmdFatalError("GetFriendList: No match for '$listString'");
    }
    return $friendList;
  }

////////////////////////////////////////////////////////////////////////////////

  function FbMatchUser($matchString, $allowRegEx) {
    global $fbFriends;
    global $fbFriendListIds;
    global $fbUser;
    global $fbObject;
    global $friendGetFields;

    if ($matchString == '') {
      return array();
    }
    $matchStringUC = strtoupper($matchString);

    // an initial equals (=) character indicates a keyword:
    if ($matchStringUC == '=ME') {
      try {
        $fbMe = $fbObject->api_client->users_getInfo($fbUser, $friendGetFields);
        return $fbMe;
      } catch (Exception $e) {
        FbCmdException('GetMe',$e);
      }
    }

    if ($matchStringUC == '=ALL') {
      return $fbFriends;
    }

    if ($matchStringUC == '=BDAY') {
      try {
        $getFields = implode($friendGetFields,",");
        $today = date("F j",time());
        $todaymatch = $today . ",";
        $fql = "SELECT {$getFields} from user where uid in (SELECT uid2 FROM friend WHERE uid1={$fbUser} AND uid2=uid2) and (birthday == '{$today}' OR substr(birthday,0," . (strlen($todaymatch)) . ") == '{$todaymatch}') ORDER BY last_name";
        $fbReturn = $fbObject->api_client->fql_query($fql);
        if (empty($fbReturn)) {
          return array();
        } else {
          return $fbReturn;
        }
      } catch (Exception $e) {
        FbCmdException('GetMe',$e);
      }
    }

    if ($matchStringUC == '=ONLINE') {
      try {
        $getFields = implode($friendGetFields,",");
        $fql = "SELECT {$getFields} from user where uid in (SELECT uid2 FROM friend WHERE uid1={$fbUser} AND uid2=uid2) and online_presence != 'offline' ORDER BY last_name";
        $fbReturn = $fbObject->api_client->fql_query($fql);
        if (empty($fbReturn)) {
          return array();
        } else {
          return $fbReturn;
        }
      } catch (Exception $e) {
        FbCmdException('GetOnline',$e);
      }
    }

    // an initial underscore character indicates a group:
    if (strncmp($matchString,'_',1)==0) {
      $matchString = substr($matchString,1);
      $matchStringUC = strtoupper($matchString);
      if ($matchString == '') {
        return array();
      }
      // first check for a numeric exact match
      if (is_numeric($matchString)) {
        foreach ($fbFriendListIds as $list) {
          if ($list['flid'] == $matchString) {
            return FbGetFriendListMembers($list['flid']);
          }
        }
        return array();
      }
      // now check for an exact match
      foreach ($fbFriendListIds as $list) {
        if (strtoupper($list['name']) == $matchStringUC) {
          return FbGetFriendListMembers($list['flid']);
        }
      }
      if ($allowRegEx == false) {
        return array();
      }
      // now match for imperfect matches, including regular expressions
      $matchList = array();
      foreach ($fbFriendListIds as $list) {
        if (eregi($matchStringUC,$list['name'])) {
          $matchList = array_merge($matchList, FbGetFriendListMembers($list['flid']));
        }
      }
      return $matchList;
    } else {
      // Not a List: check friend names
      // first check for a numeric exact match
      if (is_numeric($matchString)) {
        foreach ($fbFriends as $friend) {
          if ($friend['uid'] == $matchString) {
            return array($friend);
          }
        }
        // if no exact match, try doing a query
        try {
          $getFields = implode($friendGetFields,",");
          $fql = "SELECT {$getFields} from user where uid={$matchString}";
          $fbReturn = $fbObject->api_client->fql_query($fql);
          if (empty($fbReturn)) {
            return array();
          } else {
            return $fbReturn;
          }
        } catch (Exception $e) {
          print "** Warning: [{$e->getCode()}] {$e->getMessage()}\n";
          return array();
        }
        return array();
      }
      // next check for a perfect match firstname + lastname
      foreach ($fbFriends as $friend) {
        if (strtoupper(trim($friend['first_name'] . " " . $friend['last_name'])) == $matchStringUC) {
          return array($friend);
        }
      }
      if ($allowRegEx == false) {
        return array();
      }
      // now match for imperfect matches, including regular expressions
      $matchList = array();
      foreach ($fbFriends as $friend) {
        if (eregi($matchString,$friend['first_name'] . " " . $friend['last_name'])) {
          array_push($matchList,$friend);
        }
      }
      return $matchList;
    }
  }

  function FbGetFriendListMembers($listId) {
    global $fbObject;
    global $friendGetFields;
    try {
      $userIds = $fbObject->api_client->call_method('facebook.friends.get', array('flid' => $listId));
      $members = $fbObject->api_client->users_getInfo($userIds,$friendGetFields);
    } catch (Exception $e) {
      FbCmdException('GetFriendListMembers',$e);
    }
    return $members;
  }
////////////////////////////////////////////////////////////////////////////////

  function FbGetUserQuery($listString) {
    $matches = FbGetFriendList($listString);
    $matchIDs = array();
    foreach ($matches as $user) {
      array_push($matchIDs,$user['uid']);
    }
    return implode($matchIDs,',');
  }

////////////////////////////////////////////////////////////////////////////////

  function CheckParameters($a, $b=null)
  {
    global $argc;
    global $fbCommand;
    $num  = $argc - 2;
    if ($b == null) {
      if ($num != $a) {
        FbCmdFatalError("[{$fbCommand}] Invalid number of parameters: try fbcmd USAGE");
      }
    } else {
      if (($num < $a)||($num > $b)) {
        FbCmdFatalError("[{$fbCommand}] Invalid number of parameters: try fbcmd USAGE");
      }
    }
  }

////////////////////////////////////////////////////////////////////////////////

  function CleanPath($curPath)
  {
    if ($curPath == '') {
      return './';
    } else {
      $curPath = str_replace('\\', '/', $curPath);
      if ($curPath[strlen($curPath)-1] != '/') {
        $curPath .= '/';
      }
    }
    return $curPath;
  }

////////////////////////////////////////////////////////////////////////////////

  function GetSavePhoto($photoURL, $saveFile)
  {
    try {
      $photoContents = file_get_contents($photoURL);
      if ($photoContents == false) {
        print "**Warning: Could not download from {$photoURL}\n";
      } else {
        if (file_put_contents($saveFile, $photoContents)==false) {
          print "**Warning: Could not save {$saveFile}\n";
        }
      }
    } catch (Exception $e) {
      print "** Warning: [{$e->getCode()}] {$e->getMessage()}\n";
    }
  }

////////////////////////////////////////////////////////////////////////////////

  function CmpEventDate($a, $b)
  {
    return strcmp($a['start_time'], $b['start_time']);
  }

////////////////////////////////////////////////////////////////////////////////

  // You may want to change these display padding constants:

  function DisplayName($userObject) {
    return str_pad($userObject['first_name'] . " ". $userObject['last_name'], 30);
  }

  function DisplayId($userObject) {
    return str_pad($userObject['uid'], 12);
  }

?>
