#!ruby -Ku
#
#  ABREX
#      AUTOSAR BSW and RTE XML Generator
#
#  Copyright (C) 2013-2015 by Center for Embedded Computing Systems
#              Graduate School of Information Science, Nagoya Univ., JAPAN
#  Copyright (C) 2014-2015 by AISIN COMCRUISE Co., Ltd., JAPAN
#  Copyright (C) 2013-2015 by FUJI SOFT INCORPORATED, JAPAN
#  Copyright (C) 2014-2015 by NEC Communication Systems, Ltd., JAPAN
#  Copyright (C) 2013-2015 by Panasonic Advanced Technology Development Co., Ltd., JAPAN
#  Copyright (C) 2013-2014 by Renesas Electronics Corporation, JAPAN
#  Copyright (C) 2014-2015 by SCSK Corporation, JAPAN
#  Copyright (C) 2013-2015 by Sunny Giken Inc., JAPAN
#  Copyright (C) 2013-2015 by TOSHIBA CORPORATION, JAPAN
#  Copyright (C) 2013-2015 by Witz Corporation
#  Copyright (C) 2015 by SUZUKI MOTOR CORPORATION
#  Copyright (C) 2016 by Monami-ya LLC, Japan
#
#  上記著作権者は，以下の(1)〜(4)の条件を満たす場合に限り，本ソフトウェ
#  ア（本ソフトウェアを改変したものを含む．以下同じ）を使用・複製・改
#  変・再配布（以下，利用と呼ぶ）することを無償で許諾する．
#  (1) 本ソフトウェアをソースコードの形で利用する場合には，上記の著作
#      権表示，この利用条件および下記の無保証規定が，そのままの形でソー
#      スコード中に含まれていること．
#  (2) 本ソフトウェアを，ライブラリ形式など，他のソフトウェア開発に使
#      用できる形で再配布する場合には，再配布に伴うドキュメント（利用
#      者マニュアルなど）に，上記の著作権表示，この利用条件および下記
#      の無保証規定を掲載すること．
#  (3) 本ソフトウェアを，機器に組み込むなど，他のソフトウェア開発に使
#      用できない形で再配布する場合には，次のいずれかの条件を満たすこ
#      と．
#    (a) 再配布に伴うドキュメント（利用者マニュアルなど）に，上記の著
#        作権表示，この利用条件および下記の無保証規定を掲載すること．
#    (b) 再配布の形態を，別に定める方法によって，TOPPERSプロジェクトに
#        報告すること．
#  (4) 本ソフトウェアの利用により直接的または間接的に生じるいかなる損
#      害からも，上記著作権者およびTOPPERSプロジェクトを免責すること．
#      また，本ソフトウェアのユーザまたはエンドユーザからのいかなる理
#      由に基づく請求からも，上記著作権者およびTOPPERSプロジェクトを
#      免責すること．
#
#  本ソフトウェアは，AUTOSAR（AUTomotive Open System ARchitecture）仕
#  様に基づいている．上記の許諾は，AUTOSARの知的財産権を許諾するもので
#  はない．AUTOSARは，AUTOSAR仕様に基づいたソフトウェアを商用目的で利
#  用する者に対して，AUTOSARパートナーになることを求めている．
#
#  本ソフトウェアは，無保証で提供されているものである．上記著作権者お
#  よびTOPPERSプロジェクトは，本ソフトウェアに関して，特定の使用目的
#  に対する適合性も含めて，いかなる保証も行わない．また，本ソフトウェ
#  アの利用により直接的または間接的に生じたいかなる損害に関しても，そ
#  の責任を負わない．
#
# $Id: abrex.rb 571 2015-12-21 05:01:59Z t_ishikawa $
#

if ($0 == __FILE__)
  TOOL_ROOT = File.expand_path(File.dirname(__FILE__) + "/")
  $LOAD_PATH.unshift(TOOL_ROOT)
end

require "pp"
require "yaml"
require "optparse"
require "kconv.rb"
require "rexml/document.rb"
include REXML

######################################################################
# 定数定義
######################################################################
VERSION       = "1.1.0"
VER_INFO      = " Generated by ABREX Ver. #{VERSION} "
XML_ROOT_PATH = "/AUTOSAR/EcucDefs/"
XML_EDITION   = "4.2.0"
XML_SNAME     = "SHORT-NAME"
XML_PARAM     = "PARAMETER-VALUES"
XML_REFER     = "REFERENCE-VALUES"
XML_SUB       = "SUB-CONTAINERS"
XML_AUTOSAR_FIXED_ATT = {"xmlns"              => "http://autosar.org/schema/r4.0",
                         "xmlns:xsi"          => "http://www.w3.org/2001/XMLSchema-instance",
                         "xsi:schemaLocation" => "http://autosar.org/schema/r4.0 AUTOSAR_4-0-3_STRICT.xsd"}

# パラメータデータ型種別格納ハッシュ
# (これ以外はすべてECUC-NUMERICAL-PARAM-VALUE)
XML_VALUE_TYPE = {"ECUC-REFERENCE-DEF"               => "ECUC-REFERENCE-VALUE",
                  "ECUC-FOREIGN-REFERENCE-DEF"       => "ECUC-REFERENCE-VALUE",
                  "ECUC-SYMBOLIC-NAME-REFERENCE-DEF" => "ECUC-REFERENCE-VALUE",
                  "ECUC-INSTANCE-REFERENCE-DEF"      => "ECUC-INSTANCE-REFERENCE-VALUE",
                  "ECUC-CHOICE-REFERENCE-DEF"        => "ECUC-CHOICE-REFERENCE-DEF",
                  "ECUC-ENUMERATION-PARAM-DEF"       => "ECUC-TEXTUAL-PARAM-VALUE",
                  "ECUC-STRING-PARAM-DEF"            => "ECUC-TEXTUAL-PARAM-VALUE",
                  "ECUC-MULTILINE-STRING-PARAM-DEF"  => "ECUC-TEXTUAL-PARAM-VALUE",
                  "ECUC-FUNCTION-NAME-DEF"           => "ECUC-TEXTUAL-PARAM-VALUE",
                  "ECUC-LINKER-SYMBOL-DEF"           => "ECUC-TEXTUAL-PARAM-VALUE"}

# インスタンス参照型の特別コンテナ
XML_INSTANCE_REF_CONTAINER = {"EcucPartitionSoftwareComponentInstanceRef" =>
                                {"CONTEXT-ELEMENT-REF" => "ROOT-SW-COMPOSITION-PROTOTYPE",
                                 "TARGET-REF" => "SW-COMPONENT-PROTOTYPE"}}

######################################################################
# YAML → XML 実行機能
######################################################################
def YamlToXml(sOutputDir, aArgData, sEcuExtractRef)
  # 各パラメータのデータ型定義(-pオプションで生成したものを使用する)
  sFileName = "#{TOOL_ROOT}/param_info.yaml"
  if (!File.exist?(sFileName))
    abort("#{sFileName} not found !!")
  end
  hParamInfo = YAML.load_file(sFileName)
  # ハッシュでない(YAMLでない)場合エラー
  if (!hParamInfo.is_a?(Hash))
    abort("not YAML file !! [#{sFileName}]")
  end

  # 外部参照先のデータ型格納ハッシュを分離
  $hForeignRefType = hParamInfo.delete(:FOREIGN_REF_TYPE)

  # 選択型のコンテナ格納配列を分離
  $aChoiceContainer = hParamInfo.delete(:ECUC_CHOICE_CONTAINER_DEF)

  # インスタンス参照先のデータ型を保持
  $aInstanceRefType = hParamInfo["ECUC-INSTANCE-REFERENCE-DEF"]

  # コンテナ名変換テーブル
  $hEcuc = {}
  $hDest = {}

  hParamInfo.each{|sType, aParam|
    aParam.each{|sName|
      if (XML_VALUE_TYPE.has_key?(sType))
        $hEcuc[sName] = XML_VALUE_TYPE[sType]
      else
        $hEcuc[sName] = "ECUC-NUMERICAL-PARAM-VALUE"
      end
      $hDest[sName] = sType
    }
  }

  # 参照型のパラメータ一覧
  $hReferenceParam = hParamInfo["ECUC-REFERENCE-DEF"] + hParamInfo["ECUC-FOREIGN-REFERENCE-DEF"] + hParamInfo["ECUC-SYMBOLIC-NAME-REFERENCE-DEF"] + hParamInfo["ECUC-INSTANCE-REFERENCE-DEF"]

  # 与えられた全YAMLをマージする
  hYaml = {}
  sArxmlName = nil
  aArgData.each{|sFileName|
    # ファイルが存在しない場合エラー
    if (!File.exist?(sFileName))
      abort("Argument error !! [#{sFileName}]")
    end

    # 出力ファイル名作成(複数ある場合，最初のファイル名を採用する)
    if (File.extname(sFileName) == ".yaml")
      if (sArxmlName.nil?())
        sArxmlName = sOutputDir + "/" + File.basename(sFileName, ".yaml") + ".arxml"
      end
    else
      abort("not YAML file name !! [#{sFileName}]")
    end

    hTmpData = YAML.load(File.read(sFileName))
    # ハッシュでない(YAMLでない)場合エラー
    if (!hTmpData.is_a?(Hash))
      abort("not YAML file !! [#{sFileName}]")
    end

    # 読み込んだデータをマージしていく
    YamlToXml_merge_hash(hYaml, hTmpData)
  }

  cXmlInfo = Document.new()
  cXmlInfo.add(XMLDecl.new("1.0", "UTF-8"))
  REXML::Comment.new(VER_INFO, cXmlInfo)
  cXmlAutosar = cXmlInfo.add_element("AUTOSAR", XML_AUTOSAR_FIXED_ATT)
  cXmlArPackages = cXmlAutosar.add_element("AR-PACKAGES")

  # IMPLEMENTATION-DATA-TYPE格納ハッシュを分離して先に登録
  hImplDataType = hYaml.delete("IMPLEMENTATION-DATA-TYPE")
  if (!hImplDataType.nil?())
    cXmlArPackage = cXmlArPackages.add_element("AR-PACKAGE")
    cXmlArPackage.add_element(XML_SNAME).add_text("ImplementationDataTypes")
    cXmlElements = cXmlArPackage.add_element("ELEMENTS")
    hImplDataType.each{|sShortName, hData|
      cXmlEcucModuleConfVal = cXmlElements.add_element("IMPLEMENTATION-DATA-TYPE")
      cXmlEcucModuleConfVal.add_element(XML_SNAME).add_text(sShortName)
      cXmlEcucModuleConfVal.add_element("CATEGORY").add_text(hData["CATEGORY"])
    }
  end

  aModulePaths = []
  hYaml.each{|sPackageName, hPackageData|
    cXmlArPackage = cXmlArPackages.add_element("AR-PACKAGE")
    cXmlArPackage.add_element(XML_SNAME).add_text(sPackageName)
    cXmlElements = cXmlArPackage.add_element("ELEMENTS")

    hPackageData.each{|sEcucModuleName, hEcucModuleData|
      aModulePaths.push("/#{sPackageName}/#{sEcucModuleName}")
      cXmlEcucModuleConfVal = cXmlElements.add_element("ECUC-MODULE-CONFIGURATION-VALUES")
      cXmlEcucModuleConfVal.add_element(XML_SNAME).add_text(sEcucModuleName)
      cXmlEcucModuleConfVal.add_element("DEFINITION-REF", {"DEST" => "ECUC-MODULE-DEF"}).add_text(XML_ROOT_PATH + sEcucModuleName)
      cXmlEcucModuleConfVal.add_element("ECUC-DEF-EDITION").add_text(XML_EDITION)
      cXmlEcucModuleConfVal.add_element("IMPLEMENTATION-CONFIG-VARIANT").add_text("VARIANT-PRE-COMPILE")
      cXmlContainers = cXmlEcucModuleConfVal.add_element("CONTAINERS")

      # 各パラメータ用コンテナを作成する
      hEcucModuleData.each{|sShortName, hParamInfo|
        # DefinitionRef補完
        if (!hParamInfo.has_key?("DefinitionRef"))
          hParamInfo["DefinitionRef"] = sShortName
        end

        cContainer = YamlToXml_make_container(sShortName, hParamInfo, XML_ROOT_PATH + sEcucModuleName)
        cXmlContainers.add_element(cContainer)
      }
    }
  }

  # ECU-EXTRACT-REF指定がある場合、<ECUC-VALUE-COLLECTION>を追加する
  if (!sEcuExtractRef.nil?())
    cXmlArPackage = cXmlArPackages.add_element("AR-PACKAGE")
    cXmlArPackage.add_element(XML_SNAME).add_text("EcucValueCollection")
    cXmlElements = cXmlArPackage.add_element("ELEMENTS")
    cXmlEcucValueCollection = cXmlElements.add_element("ECUC-VALUE-COLLECTION")
    cXmlEcucValueCollection.add_element(XML_SNAME).add_text("EcucValueCollection")
    cXmlEcucValueCollection.add_element("ECU-EXTRACT-REF", {"DEST" => "SYSTEM"}).add_text(sEcuExtractRef)
    cXmlEcucValues = cXmlEcucValueCollection.add_element("ECUC-VALUES")
    aModulePaths.each{|sPath|
      cTemp = cXmlEcucValues.add_element("ECUC-MODULE-CONFIGURATION-VALUES-REF-CONDITIONAL")
      cTemp.add_element("ECUC-MODULE-CONFIGURATION-VALUES-REF", {"DEST" => "ECUC-MODULE-CONFIGURATION-VALUES"}).add_text(sPath)
    }
  end

  # XML文字列生成
  sXmlCode = String.new()
  cXmlInfo.write(sXmlCode, 2, false)

  # XML宣言の属性のコーテーションをダブルに出来ない(?)ため，ここで置換する
  sXmlCode.gsub!("'", "\"")

  # ダブルコーテーションが&quot;に変換されるのを抑止できない(?)ため，ここで置換する
  sXmlCode.gsub!("&quot;", "\"")

  # 値を定義する部分だけインデントを入れないように出来ない(?)ため，ここで置換する
  sXmlCode.gsub!(/>\n[\s]+([\w\.\[\]\(\)\+-\/\*~&;\s]*?)\n[\s]+</, ">\\1<")

  # インデントをタブに出来ない(?)ため，ここで置換する
  sXmlCode.gsub!("  ", "\t")

  # ファイル出力
  #puts(sXmlCode)
  File.open(sArxmlName, "w") {|io|
    io.puts(sXmlCode)
  }

  puts("Generated #{sArxmlName}")
end

# ハッシュマージ関数
def YamlToXml_merge_hash(hBase, hAdd)
  hAdd.each{|sKey, xVal|
    # 追加先にキーが存在しなければ，そのまま追加するのみ
    if (!hBase.has_key?(sKey))
      hBase[sKey] = xVal
    # 同じキーで値が違う場合
    elsif (hBase[sKey] != hAdd[sKey])
      # ハッシュ同士であれば，再帰で追加
      if (hBase[sKey].is_a?(Hash) && hAdd[sKey].is_a?(Hash))
        YamlToXml_merge_hash(hBase[sKey], hAdd[sKey])
      # 追加先が配列であれば，配列に合わせて追加
      elsif (hBase[sKey].is_a?(Array))
        if (hAdd[sKey].is_a?(Array))
          hBase[sKey].concat(hAdd[sKey])
        else
          hBase[sKey].push(hAdd[sKey])
        end
      # 追加先が配列でなければ，配列にしてから追加
      elsif (hAdd[sKey].is_a?(Array))
        hBase[sKey] = [hBase[sKey]]
        hBase[sKey].concat(hAdd[sKey])
      # どちらも配列でない場合，配列として両方をマージ
      else
        hBase[sKey] = [hBase[sKey]]
        hBase[sKey].push(hAdd[sKey])
      end
    else
      # 同じパラメータの場合，何もしない
    end
  }
end

# コンテナ作成関数
def YamlToXml_make_container(sShortName, hParamInfo, sPath)
  # 一律"ECUC-CONTAINER-VALUE"を入れた状態で初期化
  cContainer = Element.new().add_element("ECUC-CONTAINER-VALUE")

  # ショートネーム追加
  cContainer.add_element(XML_SNAME).add_text(sShortName)

  # コンテナまでのパス追加
  if ($aChoiceContainer.include?(hParamInfo["DefinitionRef"]))
    cContainer.add_element("DEFINITION-REF", {"DEST" => "ECUC-CHOICE-CONTAINER-DEF"}).add_text("#{sPath}/#{hParamInfo["DefinitionRef"]}")
  else
    cContainer.add_element("DEFINITION-REF", {"DEST" => "ECUC-PARAM-CONF-CONTAINER-DEF"}).add_text("#{sPath}/#{hParamInfo["DefinitionRef"]}")
  end

  # 各パラメータ設定(パラメータが無い場合は不要)
  hCheck= {}
  if (hParamInfo.size() != 1)
    hCheck[XML_PARAM] = false
    hCheck[XML_REFER] = false
    hCheck[XML_SUB] = false

    # まず参照型，サブコンテナ以外を生成(AUTOSARスキーマ制約)
    hParamInfo.each{|sParamName, sahValue|
      if ((sParamName == "DefinitionRef") || (sahValue.is_a?(Hash)))
        next
      end

      # 参照型，サブコンテナ以外のパラメータ
      if (!$hReferenceParam.include?(sParamName))
        # パラメータ名チェック
        if (!$hEcuc.has_key?(sParamName) || !$hDest.has_key?(sParamName))
          abort("Unknown parameter: #{sParamName}")
        end

        if (hCheck[XML_PARAM] == false)
          cContainer.add_element(XML_PARAM)
          hCheck[XML_PARAM] = true
        end

        # 多重度*対応
        aTemp = []
        if (sahValue.is_a?(Array))
          aTemp = sahValue
        else
          aTemp.push(sahValue)
        end
        aTemp.each{|sVal|
          cParamContainer_ = Element.new()
          cParamContainer = cParamContainer_.add_element($hEcuc[sParamName])
          cParamContainer.add_element("DEFINITION-REF", {"DEST" => $hDest[sParamName]}).add_text("#{sPath}/#{hParamInfo["DefinitionRef"]}/#{sParamName}")
          cParamContainer.add_element("VALUE").add_text(sVal.to_s())
          cContainer.elements[XML_PARAM].add_element(cParamContainer)
        }
      end
    }

    # 次に参照型を生成(AUTOSARスキーマ制約)
    hParamInfo.each{|sParamName, sahValue|
      if ((sParamName == "DefinitionRef") || (sahValue.is_a?(Hash)))
        next
      end

      # インスタンス参照型の場合
      if ($aInstanceRefType.include?(sParamName))
        if (!sahValue.is_a?(Array))
          abort("#{sParamName} must be Array !!")
        end
        # 未サポートコンテナは生成できないためエラーとする
        if (!XML_INSTANCE_REF_CONTAINER.has_key?(sParamName))
          abort("#{sParamName} is not supported !!")
        end
        if (hCheck[XML_REFER] == false)
          cContainer.add_element(XML_REFER)
          hCheck[XML_REFER] = true
        end

        # 多重度*対応(2次元配列かチェック)
        aTemp = []
        if (sahValue[0].is_a?(Array))
          aTemp = sahValue
        else
          aTemp.push(sahValue)
        end
        aTemp.each{|aVal|
          cParamContainer_ = Element.new()
          cParamContainer = cParamContainer_.add_element($hEcuc[sParamName])
          cParamContainer.add_element("DEFINITION-REF", {"DEST" => $hDest[sParamName]}).add_text("#{sPath}/#{hParamInfo["DefinitionRef"]}/#{sParamName}")
          cInstanceRef = cParamContainer.add_element("VALUE-IREF")
          aVal.each{|hVal|
            XML_INSTANCE_REF_CONTAINER[sParamName].each{|sParam, sDest|
              if (hVal.has_key?(sParam))
                cInstanceRef.add_element(sParam, {"DEST" => sDest}).add_text(hVal[sParam].to_s())
              end
            }
          }
          cContainer.elements[XML_REFER].add_element(cParamContainer)
        }

      # 参照型の場合
      elsif ($hReferenceParam.include?(sParamName))
        if (hCheck[XML_REFER] == false)
          cContainer.add_element(XML_REFER)
          hCheck[XML_REFER] = true
        end

        # 多重度*対応
        aTemp = []
        if (sahValue.is_a?(Array))
          aTemp = sahValue
        else
          aTemp.push(sahValue)
        end
        aTemp.each{|sVal|
          cParamContainer_ = Element.new()
          cParamContainer = cParamContainer_.add_element($hEcuc[sParamName])
          cParamContainer.add_element("DEFINITION-REF", {"DEST" => $hDest[sParamName]}).add_text("#{sPath}/#{hParamInfo["DefinitionRef"]}/#{sParamName}")
          if (!$hForeignRefType.nil? && $hForeignRefType.has_key?(sParamName))
            cParamContainer.add_element("VALUE-REF", {"DEST" => $hForeignRefType[sParamName]}).add_text(sVal.to_s())
          else
            cParamContainer.add_element("VALUE-REF", {"DEST" => "ECUC-CONTAINER-VALUE"}).add_text(sVal.to_s())
          end
          cContainer.elements[XML_REFER].add_element(cParamContainer)
        }
      end
    }

    # 最後にサブコンテナを生成
    hParamInfo.each{|sParamName, sahValue|
      if ((sParamName == "DefinitionRef") || (!sahValue.is_a?(Hash)))
        next
      end

      if (hCheck[XML_SUB] == false)
        cContainer.add_element(XML_SUB)
        hCheck[XML_SUB] = true
      end

      # DefinitionRef補完
      if (!sahValue.has_key?("DefinitionRef"))
        sahValue["DefinitionRef"] = sParamName
      end

      # 再帰でサブコンテナを作成する
      cContainer.elements[XML_SUB].add_element(YamlToXml_make_container(sParamName, sahValue, "#{sPath}/#{hParamInfo["DefinitionRef"]}"))
    }
  end

  return cContainer
end


######################################################################
# XML → YAML 実行機能
######################################################################
def XmlToYaml(sOutputDir, sFirstFile, aExtraFile)
#  aExtraFile.unshift(sFirstFile)
  aExtraFile.each{|sFileName|
    # ファイルが存在しない場合エラー
    if (!File.exist?(sFileName))
      abort("Argument error !! [#{sFileName}]")
    end

    # 出力ファイル名作成
    if (File.extname(sFileName) == ".arxml")
      sYamlName = sOutputDir + "/" + File.basename(sFileName, ".arxml") + ".yaml"
    else
      abort("not ARXML file !! [#{sFileName}]")
    end

    # XMLライブラリでの読み込み
    cXmlData = REXML::Document.new(open(sFileName))

    hResult = {}

    cXmlData.elements.each("AUTOSAR/AR-PACKAGES/AR-PACKAGE"){|cElement1|
      cElement1.elements.each("ELEMENTS/ECUC-MODULE-CONFIGURATION-VALUES"){|cElement2|
        sPackageName = cElement1.elements["SHORT-NAME"].text()
        if (!hResult.has_key?(sPackageName))
          hResult[sPackageName] = {}
        end

        sModuleName = cElement2.elements["SHORT-NAME"].text()
        hResult[sPackageName][sModuleName] = {}

        cElement2.elements.each("CONTAINERS/ECUC-CONTAINER-VALUE"){|cElement3|
          XmlToYaml_parse_parameter(cElement3, hResult[sPackageName][sModuleName])
        }
      }
    }

    # YAMLファイル出力
    open(sYamlName, "w") do |io|
      YAML.dump(hResult, io)
    end

    # YAML整形処理
    # ・先頭の区切り文字削除
    # ・コーテーションの削除
    # ・配列のインデント整列
    sFileData = File.read(sYamlName)
    sFileData.gsub!(/^---$/, "")
    sFileData.gsub!("'", "")
    sFileData.gsub!(/^(\s+)-(\s.*)$/, "\\1  -\\2")
    File.write(sYamlName, sFileData)

    puts("Generated #{sYamlName}")
  }
end

# コンテナパース関数
def XmlToYaml_parse_parameter(cElement, hTarget)
  sParamShortName = cElement.elements["SHORT-NAME"].text()
  sParamDefName = cElement.elements["DEFINITION-REF"].text().split("/")[-1]
  hTarget[sParamShortName] = {}
  if (sParamShortName != sParamDefName)
    hTarget[sParamShortName]["DefinitionRef"] = sParamDefName
  end

  # パラメータ
  cElement.elements.each("PARAMETER-VALUES"){|cElementC|
    ["ECUC-NUMERICAL-PARAM-VALUE", "ECUC-TEXTUAL-PARAM-VALUE"].each{|sParamValue|
      cElementC.elements.each(sParamValue){|cElementG|
        sName = cElementG.elements["DEFINITION-REF"].text().split("/")[-1]
        sValue = cElementG.elements["VALUE"].text()
        # 複数多重度対応
        if (hTarget[sParamShortName].has_key?(sName))
          if (hTarget[sParamShortName][sName].is_a?(Array))
            # 既に複数ある場合は配列に追加
            hTarget[sParamShortName][sName].push(sValue)
          else
            # 1つだけ定義されていた場合は配列に変更
            sTemp = hTarget[sParamShortName][sName]
            hTarget[sParamShortName][sName] = [sTemp, sValue]
          end
        else
          hTarget[sParamShortName][sName] = sValue
        end
      }
    }
  }

  # 参照，外部参照，選択参照
  cElement.elements.each("REFERENCE-VALUES/ECUC-REFERENCE-VALUE"){|cElementC|
    sName = cElementC.elements["DEFINITION-REF"].text().split("/")[-1]
    if (cElementC.elements["VALUE-REF"].nil?)
      abort("<VALUE> is not found in '#{sParamShortName}'")
    end
    sValue = cElementC.elements["VALUE-REF"].text()
    # 複数多重度対応
    if (hTarget[sParamShortName].has_key?(sName))
      if (hTarget[sParamShortName][sName].is_a?(Array))
        # 既に複数ある場合は配列に追加
        hTarget[sParamShortName][sName].push(sValue)
      else
        # 1つだけ定義されていた場合は配列に変更
        sTemp = hTarget[sParamShortName][sName]
        hTarget[sParamShortName][sName] = [sTemp, sValue]
      end
    else
      hTarget[sParamShortName][sName] = sValue
    end
  }

  # インスタンス参照
  cElement.elements.each("REFERENCE-VALUES/ECUC-INSTANCE-REFERENCE-VALUE"){|cElementC|
    sName = cElementC.elements["DEFINITION-REF"].text().split("/")[-1]
    hTarget[sParamShortName][sName] = []
    hTarget[sParamShortName][sName].push({"CONTEXT-ELEMENT-REF" => cElementC.elements["VALUE-IREF"].elements["CONTEXT-ELEMENT-REF"].text()})
    hTarget[sParamShortName][sName].push({"TARGET-REF" => cElementC.elements["VALUE-IREF"].elements["TARGET-REF"].text()})
  }

  # サブコンテナ(再帰呼出し)
  cElement.elements.each("SUB-CONTAINERS/ECUC-CONTAINER-VALUE"){|cElementC|
    XmlToYaml_parse_parameter(cElementC, hTarget[sParamShortName])
  }
end


######################################################################
# AUTOSARパラメータ情報ファイル作成
######################################################################
def MakeParamInfo(sFileName)
  # ファイルが存在しない場合エラー
  if (!File.exist?(sFileName))
    abort("Argument error !! [#{sFileName}]")
  end

  sParamFileName = File.dirname(sFileName) + "/param_info.yaml"

  # 読み込み対象モジュール
  aTargetModule = ["Rte", "Os", "Com", "PduR", "CanIf", "Can", "EcuC", "EcuM", "WdgM", "WdgIf", "Wdg", "Dem"]

  # XMLライブラリでの読み込み
  cXmlData = REXML::Document.new(open(sFileName))

  # 外部参照先のデータ型格納ハッシュ
  $hForeignRefType = {}

  # 選択型のコンテナ格納配列
  $aChoiceContainer = []

  # パース結果格納ハッシュ初期化(NCES仕様コンテナは予め設定)
  sNcesContainer = <<-EOS
ECUC-ENUMERATION-PARAM-DEF:
  - OsMemorySectionInitialize
  - OsIsrInterruptSource
  - OsInterCoreInterruptInterruptSource
  - OsSpinlockLockMethod
  - WdgTriggerMode
  - WdgTimeoutReaction
ECUC-INTEGER-PARAM-DEF:
  - OsMasterCoreId
  - OsHookStackSize
  - OsHookStackCoreAssignment
  - OsOsStackSize
  - OsOsStackCoreAssignment
  - OsNonTrustedHookStackSize
  - OsNonTrustedHookStackCoreAssignment
  - OsTaskStackSize
  - OsTaskSystemStackSize
  - OsIsrInterruptNumber
  - OsIsrInterruptPriority
  - OsIsrStackSize
  - OsTrustedFunctionStackSize
  - OsInterCoreInterruptStackSize
  - OsMemoryRegionSize
  - OsMemoryRegionStartAddress
  - OsMemoryAreaSize
  - OsStandardMemoryCoreAssignment
  - OsIsrMaxFrequency
  - WdgWindowOpenRate
ECUC-STRING-PARAM-DEF:
  - OsIncludeFileName
  - OsMemoryRegionName
  - OsMemoryAreaStartAddress
  - OsMemorySectionName
  - OsMemoryModuleName
  - OsLinkSectionName
  - OsIocPrimitiveDataType
  - OsIocIncludeFile
  - OsHookStackStartAddress
  - OsOsStackStartAddress
  - OsNonTrustedHookStackStartAddress
  - OsTaskStackStartAddress
  - OsTaskSystemStackStartAddress
  - OsInterCoreInterruptStackStartAddress
ECUC-BOOLEAN-PARAM-DEF:
  - OsMemoryRegionWriteable
  - OsMemoryAreaWriteable
  - OsMemoryAreaReadable
  - OsMemoryAreaExecutable
  - OsMemoryAreaCacheable
  - OsMemoryAreaDevice
  - OsMemorySectionWriteable
  - OsMemorySectionReadable
  - OsMemorySectionExecutable
  - OsMemorySectionShort
  - OsMemorySectionCacheable
  - OsMemorySectionDevice
  - OsMemorySectionExport
  - OsMemoryModuleExport
  - OsTaskOsInterruptLockMonitor
  - OsTaskResourceLockMonitor
ECUC-REFERENCE-DEF:
  - OsStandardMemoryRomRegionRef
  - OsStandardMemoryRamRegionRef
  - OsAppStandardMemoryRomRegionRef
  - OsAppStandardMemoryRamRegionRef
  - OsMemorySectionMemoryRegionRef
  - OsLinkSectionMemoryRegionRef
  - OsResourceLinkedResourceRef
  - OsCounterIsrRef
  - OsAppMemorySectionRef
  - OsAppMemoryModuleRef
  - OsAppMemoryAreaRef
  - OsAppInterCoreInterruptRef
  - OsInterCoreInterruptAccessingApplication
  - OsInterCoreInterruptResourceRef
  - WdgMOsCounterRef
  - OsSystemCycleTimeWindowRef
ECUC-FLOAT-PARAM-DEF:
  - OsSystemCycleTime
  - OsSystemCycleTimeWindowStart
  - OsSystemCycleTimeWindowLength
  - OsOsInterruptLockBudget
  - OsResourceLockBudget
  - OsTrustedFunctionExecutionBudget
  - WdgTimeout
  - WdgTriggerInterruptPeriod
EOS
  $hResult = YAML.load(sNcesContainer)

  cXmlData.elements.each("AUTOSAR/AR-PACKAGES/AR-PACKAGE/AR-PACKAGES/AR-PACKAGE/ELEMENTS/ECUC-MODULE-DEF"){|cElement1|
    # 対象モジュールのみを処理する
    if (!aTargetModule.include?(cElement1.elements["SHORT-NAME"].text()))
      next
    end

    cElement1.elements.each("CONTAINERS/ECUC-PARAM-CONF-CONTAINER-DEF"){|cElement2|
      MakeParamInfo_parse_parameter(cElement2)
    }
  }

  # パラメータ名でソートと重複除去
  hResultSort = {}
  $hResult.each{|sType, aParam|
    hResultSort[sType] = aParam.uniq().sort()
  }

  # 外部参照先のデータ型格納ハッシュを結合
  if (!$hForeignRefType.empty?())
    hResultSort[:FOREIGN_REF_TYPE] = $hForeignRefType
  end

  # 選択型のコンテナ格納配列を追加
  if (!$aChoiceContainer.empty?())
    hResultSort[:ECUC_CHOICE_CONTAINER_DEF] = $aChoiceContainer
  end

  # RteSoftwareComponentInstanceRefは外部参照とインスタンス参照の
  # 両方に含まれるが，外部参照として扱う
  hResultSort["ECUC-INSTANCE-REFERENCE-DEF"].delete("RteSoftwareComponentInstanceRef")

  # YAMLファイル出力
  open(sParamFileName, "w") do |io|
    YAML.dump(hResultSort, io)
  end

  puts("Generated #{sParamFileName}")
end

# サブコンテナ再帰パース関数
def MakeParamInfo_parse_sub_container(cElement)
  # "ECUC-PARAM-CONF-CONTAINER-DEF"が登場するまで再帰する
  cElement.elements.each{|cElementC|
    # CHOICEはさらにネストする
    if (cElementC.name == "ECUC-CHOICE-CONTAINER-DEF")
      $aChoiceContainer.push(cElementC.elements[XML_SNAME].text())
      MakeParamInfo_parse_sub_container(cElementC)
    elsif (cElementC.name == "ECUC-PARAM-CONF-CONTAINER-DEF")
      MakeParamInfo_parse_parameter(cElementC)
    else
      MakeParamInfo_parse_sub_container(cElementC)
    end
  }
end

# コンテナパース関数
def MakeParamInfo_parse_parameter(cElement)
  # パラメータ
  cElement.elements.each("PARAMETERS"){|cElementC|
    cElementC.elements.each{|cElementG|
      # 初出のデータ型処理
      if (!$hResult.has_key?(cElementG.name))
        $hResult[cElementG.name] = []
      end

      # 取得したパラメータ名を格納する
      $hResult[cElementG.name].push(cElementG.elements["SHORT-NAME"].text())
    }
  }

  # 参照
  cElement.elements.each("REFERENCES/ECUC-REFERENCE-DEF"){|cElementC|
    $hResult["ECUC-REFERENCE-DEF"].push(cElementC.elements["SHORT-NAME"].text())
  }

  # 外部参照
  cElement.elements.each("REFERENCES/ECUC-FOREIGN-REFERENCE-DEF"){|cElementC|
    # 初出のデータ型処理
    if (!$hResult.has_key?("ECUC-FOREIGN-REFERENCE-DEF"))
      $hResult["ECUC-FOREIGN-REFERENCE-DEF"] = []
    end
    $hResult["ECUC-FOREIGN-REFERENCE-DEF"].push(cElementC.elements["SHORT-NAME"].text())
    $hForeignRefType[cElementC.elements["SHORT-NAME"].text()] = cElementC.elements["DESTINATION-TYPE"].text()
  }

  # 選択参照
  cElement.elements.each("REFERENCES/ECUC-CHOICE-REFERENCE-DEF"){|cElementC|
    # 初出のデータ型処理
    if (!$hResult.has_key?("ECUC-CHOICE-REFERENCE-DEF"))
      $hResult["ECUC-CHOICE-REFERENCE-DEF"] = []
    end
    $hResult["ECUC-CHOICE-REFERENCE-DEF"].push(cElementC.elements["SHORT-NAME"].text())
  }

  # シンボル参照
  cElement.elements.each("REFERENCES/ECUC-SYMBOLIC-NAME-REFERENCE-DEF"){|cElementC|
    # 初出のデータ型処理
    if (!$hResult.has_key?("ECUC-SYMBOLIC-NAME-REFERENCE-DEF"))
      $hResult["ECUC-SYMBOLIC-NAME-REFERENCE-DEF"] = []
    end
    $hResult["ECUC-SYMBOLIC-NAME-REFERENCE-DEF"].push(cElementC.elements["SHORT-NAME"].text())
  }

  # インスタンス参照
  cElement.elements.each("REFERENCES/ECUC-INSTANCE-REFERENCE-DEF"){|cElementC|
    # 初出のデータ型処理
    if (!$hResult.has_key?("ECUC-INSTANCE-REFERENCE-DEF"))
      $hResult["ECUC-INSTANCE-REFERENCE-DEF"] = []
    end
    $hResult["ECUC-INSTANCE-REFERENCE-DEF"].push(cElementC.elements["SHORT-NAME"].text())
  }

  # サブコンテナ(再帰呼出し)
  cElement.elements.each("SUB-CONTAINERS"){|cElementC|
    MakeParamInfo_parse_sub_container(cElementC)
  }
end


######################################################################
# ジェネレータ用csvファイルの生成
######################################################################
def MakeCsv(sFileName, sTargetModule)
  # ファイルが存在しない場合エラー
  if (!File.exist?(sFileName))
    abort("Argument error !! [#{sFileName}]")
  end

  sCsvFileName = File.dirname(sFileName) + "/" + sTargetModule + ".csv"

  # XMLライブラリでの読み込み
  cXmlData = REXML::Document.new(open(sFileName))

  $hResult = {}
  $sNowContainer = ""

  cXmlData.elements.each("AUTOSAR/AR-PACKAGES/AR-PACKAGE/AR-PACKAGES/AR-PACKAGE/ELEMENTS/ECUC-MODULE-DEF"){|cElement1|
    # 対象モジュールのみを処理する
    if (cElement1.elements["SHORT-NAME"].text() != sTargetModule)
      next
    end

    cElement1.elements.each("CONTAINERS/ECUC-PARAM-CONF-CONTAINER-DEF"){|cElement2|
      $sContainer = cElement2.elements["SHORT-NAME"].text()
      $hResult[$sContainer] = MakeCsv_add_parameter_info(cElement2, nil)
      MakeCsv_parse_parameter(cElement2)
    }
  }

  sModulePath = "/AUTOSAR/EcucDefs/#{sTargetModule}"
  sCsvData = "#{sModulePath},,,1\n"

  hDataTypeTable = {"ECUC-REFERENCE-DEF"               => "REF",
                    "ECUC-FOREIGN-REFERENCE-DEF"       => "REF",
                    "ECUC-CHOICE-REFERENCE-DEF"        => "REF",
                    "ECUC-SYMBOLIC-NAME-REFERENCE-DEF" => "REF",
                    "ECUC-INSTANCE-REFERENCE-DEF"      => "REF",
                    "ECUC-BOOLEAN-PARAM-DEF"           => "BOOLEAN",
                    "ECUC-INTEGER-PARAM-DEF"           => "INT",
                    "ECUC-FUNCTION-NAME-DEF"           => "FUNCTION",
                    "ECUC-ENUMERATION-PARAM-DEF"       => "ENUM",
                    "ECUC-STRING-PARAM-DEF"            => "STRING",
                    "ECUC-FLOAT-PARAM-DEF"             => "FLOAT",
                    "ECUC-LINKER-SYMBOL-DEF"           => "STRING",
                    nil                                => ""}

  $hResult.each{|sParam, aInfo|
    if (!hDataTypeTable.has_key?(aInfo[0]))
      abort("[#{__FILE__}] #{__LINE__}: #{aInfo[0]}")
    end
    if ((aInfo[1] == "1") && (aInfo[2] == "1"))
      sCsvData += "#{sModulePath}/#{sParam},#{sParam.split("/")[-1]},#{hDataTypeTable[aInfo[0]]},1\n"
    else
      sCsvData += "#{sModulePath}/#{sParam},#{sParam.split("/")[-1]},#{hDataTypeTable[aInfo[0]]},#{aInfo[1]},#{aInfo[2]}\n"
    end
  }

  File.open(sCsvFileName, "w") {|io|
    io.puts(sCsvData)
  }

  puts("Generated #{sCsvFileName}")
end

# パラメータ情報追加関数
def MakeCsv_add_parameter_info(cElement, sName = cElement.name)
  # パラメータ毎に，型・多重度下限，上限の情報を取得
  sLower = nil
  if (!cElement.elements["LOWER-MULTIPLICITY"].nil?)
    sLower = cElement.elements["LOWER-MULTIPLICITY"].text()
  else
    abort("[#{__FILE__}] #{__LINE__}")
  end
  sUpper = nil
  if (!cElement.elements["UPPER-MULTIPLICITY"].nil?)
    sUpper = cElement.elements["UPPER-MULTIPLICITY"].text()
  elsif (!cElement.elements["UPPER-MULTIPLICITY-INFINITE"].nil? && (cElement.elements["UPPER-MULTIPLICITY-INFINITE"].text() == "true"))
    sUpper = "*"
  else
    abort("[#{__FILE__}] #{__LINE__}")
  end

  return [sName, sLower, sUpper]
end

# サブコンテナ再帰パース関数
def MakeCsv_parse_sub_container(cElement)
  # "ECUC-PARAM-CONF-CONTAINER-DEF"が登場するまで再帰する
  cElement.elements.each{|cElementC|
    # CHOICEはさらにネストする
    if (cElementC.name == "ECUC-CHOICE-CONTAINER-DEF")
      $sContainer += "/#{cElementC.elements["SHORT-NAME"].text()}"
      $hResult[$sContainer] = MakeCsv_add_parameter_info(cElementC, nil)
      MakeCsv_parse_sub_container(cElementC)

      aTemp = $sContainer.split("/")
      aTemp.pop()
      $sContainer = aTemp.join("/")
    elsif (cElementC.name == "ECUC-PARAM-CONF-CONTAINER-DEF")
      $sContainer += "/#{cElementC.elements["SHORT-NAME"].text()}"
      $hResult[$sContainer] = MakeCsv_add_parameter_info(cElementC, nil)
      MakeCsv_parse_parameter(cElementC)

      aTemp = $sContainer.split("/")
      aTemp.pop()
      $sContainer = aTemp.join("/")
    else
      MakeCsv_parse_sub_container(cElementC)
    end
  }
end

# コンテナパース関数
def MakeCsv_parse_parameter(cElement)
  # パラメータ
  cElement.elements.each("PARAMETERS"){|cElementC|
    cElementC.elements.each{|cElementG|
      sParamName = "#{$sContainer}/#{cElementG.elements["SHORT-NAME"].text()}"
      $hResult[sParamName] = MakeCsv_add_parameter_info(cElementG)
    }
  }

  # 参照
  cElement.elements.each("REFERENCES/ECUC-REFERENCE-DEF"){|cElementC|
    sParamName = "#{$sContainer}/#{cElementC.elements["SHORT-NAME"].text()}"
    $hResult[sParamName] = MakeCsv_add_parameter_info(cElementC)
  }

  # 外部参照
  cElement.elements.each("REFERENCES/ECUC-FOREIGN-REFERENCE-DEF"){|cElementC|
    sParamName = "#{$sContainer}/#{cElementC.elements["SHORT-NAME"].text()}"
    $hResult[sParamName] = MakeCsv_add_parameter_info(cElementC)
  }

  # 選択参照
  cElement.elements.each("REFERENCES/ECUC-CHOICE-REFERENCE-DEF"){|cElementC|
    sParamName = "#{$sContainer}/#{cElementC.elements["SHORT-NAME"].text()}"
    $hResult[sParamName] = MakeCsv_add_parameter_info(cElementC)
  }

  # シンボルネーム参照
  cElement.elements.each("REFERENCES/ECUC-SYMBOLIC-NAME-REFERENCE-DEF"){|cElementC|
    sParamName = "#{$sContainer}/#{cElementC.elements["SHORT-NAME"].text()}"
    $hResult[sParamName] = MakeCsv_add_parameter_info(cElementC)
  }

  # インスタンス参照
  cElement.elements.each("REFERENCES/ECUC-INSTANCE-REFERENCE-DEF"){|cElementC|
    sParamName = "#{$sContainer}/#{cElementC.elements["SHORT-NAME"].text()}"
    $hResult[sParamName] = MakeCsv_add_parameter_info(cElementC)
  }

  # サブコンテナ(再帰呼出し)
  cElement.elements.each("SUB-CONTAINERS"){|cElementC|
    MakeCsv_parse_sub_container(cElementC)
  }
end


######################################################################
# オプション処理
######################################################################
#lMode = :YamlToXml
#sEcuExtractRef = nil
#cOpt = OptionParser.new(banner="Usage: abrex.rb [options]... [yaml|xml files]...", 18)
#cOpt.version = VERSION
#sOptData = nil
#sBswName = nil
#cOpt.on("-i XML_FILE", "ARXML to YAML conversion") {|xVal|
#  sOptData = xVal
#  lMode = :XmlToYaml
#}
#cOpt.on("-p XML_FILE", "Generate 'param_info.yaml' from AUTOSAR Ecu Configuration Parameters file") {|xVal|
#  sOptData = xVal
#  lMode = :MakeParamInfo
#}
#cOpt.on("-c XML_FILE", "Generate '{BSW_NAME}.csv' from AUTOSAR Ecu Configuration Parameters file") {|xVal|
#  sOptData = xVal
#  lMode = :MakeCsv
#}
#cOpt.on("-b BSW_NAME", "set a BSW Module Name (for '-c' additional optipn)") {|xVal|
#  sBswName = xVal
#  lMode = :MakeCsv
#}
#cOpt.on("-e ECU-EXTRACT-REF", "set a ECU-EXTRACT-REF path if <ECUC-VALUE-COLLECTION> is needed") {|xVal|
#  sEcuExtractRef = xVal
#  lMode = :YamlToXml
#}
#cOpt.on("-v", "--version", "show version information"){
#  puts(cOpt.ver())
#  exit(1)
#}
#cOpt.on("-h", "--help", "show help (this)"){
#  puts(cOpt.help())
#  exit(1)
#}
#
#begin
#  aArgData = cOpt.parse(ARGV)
#rescue OptionParser::ParseError
#  puts(cOpt.help())
#  exit(1)
#end
#
#if (((lMode == :YamlToXml) && aArgData.empty?()) ||
#    ((lMode != :YamlToXml) && sOptData.nil?()))
#  puts(cOpt.help())
#  exit(1)
#end
#
#if ((lMode == :MakeCsv) && sBswName.nil?())
#  puts(cOpt.help())
#  exit(1)
#end


######################################################################
# オプションに従って各処理を実行
######################################################################
#case lMode
#  when :YamlToXml
#    YamlToXml(aArgData, sEcuExtractRef)
#  when :XmlToYaml
#    XmlToYaml(sOptData, aArgData)
#  when :MakeParamInfo
#    MakeParamInfo(sOptData)
#  when :MakeCsv
#    MakeCsv(sOptData, sBswName)
#end
