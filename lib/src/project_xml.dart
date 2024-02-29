import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:xml/xml.dart';

class ProjectXml{
  final String path;
  ProjectXml(this.path);
  readXML(String caminho){
    //final file =  File(caminho);
   // final document = XmlDocument.parse(file.readAsStringSync());
    final document = XmlDocument.parse(caminho);
    return document;
  }
  writeXML(){}
  taskAsArray(){}
}