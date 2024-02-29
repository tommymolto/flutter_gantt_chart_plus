import 'package:xml/xml.dart';

class _Xml2JsonGData {
  final String _marker = '"VALUE"'.toLowerCase();
  final String _xmlnsPrefix = '"xmlns"';
  final String _cdata = '"__cdata"';

  /// GData transformer function.
  Map<dynamic, dynamic> _transform(XmlDocument node) {
    final json = <dynamic, dynamic>{};

    void _process(dynamic node, dynamic obj, dynamic ns) {
      if (node is XmlText) {
        /* Text node processing */
        final sanitisedNodeData = _Xml2JsonUtils.escapeTextForJson(node.text);
        final nodeData = '"$sanitisedNodeData"';
        if (obj['$_marker'] is List) {
          obj['$_marker'].add(nodeData);
        } else if (obj['$_marker'] is Map) {
          obj['$_marker'] = <dynamic>[obj['$_marker'], nodeData];
        } else {
          obj['$_marker'] = nodeData;
        }
      } else if (node is XmlElement) {
        /* Element node processing */
        final p = <dynamic, dynamic>{};
        var nodeName = '"${node.name}"'.toLowerCase();
        nodeName = nodeName.replaceAll(':', '\$');

        for (var i = 0; i < node.attributes.length; i++) {
          final attr = node.attributes[i];
          final name = attr.name.qualified.toLowerCase();
          dynamic value = attr.value;
          // If the value is double quoted fix it.
          if (value.startsWith('"') && value.endsWith('"')) {
            value = value.substring(1, value.length - 1);
          }
          if (name == 'xmlns') {
            ns['"$name"'] = '"$value"';
          } else if (name.indexOf('xmlns:') == 0) {
            var namePrefix = name.replaceAll(':', '\$');
            namePrefix = '"$namePrefix"';
            ns[namePrefix] = '"$value"';
          } else {
            final indexName = '"$name"';
            p[indexName] = '"$value"';
          }
        }

        if (ns.isNotEmpty) {
          for (final String prefix in ns.keys) {
            if (!p.containsKey(_xmlnsPrefix)) {
              final pList = [<dynamic, dynamic>{}];
              p[_xmlnsPrefix] = pList;
            }
            p[prefix] = ns[prefix];
          }
        }

        if (obj[nodeName] is List) {
          obj[nodeName].add(p);
        } else if (obj[nodeName] is Map) {
          obj[nodeName] = <dynamic>[obj[nodeName], p];
        } else {
          obj[nodeName] = p;
        }

        for (var j = 0; j < node.children.length; j++) {
          _process(node.children[j], p, <dynamic, dynamic>{});
        }
      } else if (node is XmlDocument) {
        /* Document node processing */
        for (var k = 0; k < node.children.length; k++) {
          _process(node.children[k], obj, <dynamic, dynamic>{});
        }
      } else if (node is XmlCDATA) {
        /* CDATA node processing */
        final sanitisedNodeData = _Xml2JsonUtils.escapeTextForJson(node.text);
        final nodeData = '"$sanitisedNodeData"';
        obj['$_cdata'] = nodeData;
      } else if (node is XmlProcessing) {
        /* Processing node, only text in this node */
        final processingString = node.text;
        final nodeMap = _Xml2JsonUtils.mapProcessingNode(processingString);
        for (final i in nodeMap.keys) {
          final index = '"$i"';
          final sanitisedNodeData =
          _Xml2JsonUtils.escapeTextForJson(nodeMap[i]);
          final nodeData = '"$sanitisedNodeData"';
          obj[index] = nodeData;
        }
      }
    }

    _process(node, json, <dynamic, dynamic>{});
    return json;
  }

  /// Transformer function
  String transform(XmlDocument xmlNode) {
    Map<dynamic, dynamic> json;
    try {
      json = _transform(xmlNode);
    } on Exception catch (e) {
      throw Xml2JsonException(
          'GData internal transform error => ${e.toString()}');
    }
    return json.toString();
  }
}