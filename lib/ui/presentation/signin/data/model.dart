// To parse this JSON data, do
//
//     final loginResponseModel = loginResponseModelFromJson(jsonString);

import 'dart:convert';

LoginResponseModel loginResponseModelFromJson(String str) =>
    LoginResponseModel.fromJson(json.decode(str));

String loginResponseModelToJson(LoginResponseModel data) =>
    json.encode(data.toJson());

class LoginResponseModel {
  final String? jsonrpc;
  final dynamic id;
  final Result? result;

  LoginResponseModel({
    this.jsonrpc,
    this.id,
    this.result,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) =>
      LoginResponseModel(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: json["result"] == null ? null : Result.fromJson(json["result"]),
      );

  Map<String, dynamic> toJson() => {
        "jsonrpc": jsonrpc,
        "id": id,
        "result": result?.toJson(),
      };
}

class Result {
  final String? message;
  final bool? success;
  final Data? data;
  final String? token;

  Result({
    this.message,
    this.success,
    this.data,
    this.token,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        message: json["message"],
        success: json["success"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
        token: json["token"],
      );

  Map<String, dynamic> toJson() => {
        "message": message,
        "success": success,
        "data": data?.toJson(),
        "token": token,
      };
}

class Data {
  final int? uid;
  final bool? isSystem;
  final bool? isAdmin;
  final UserContext? userContext;
  final String? db;
  final String? serverVersion;
  final List<dynamic>? serverVersionInfo;
  final String? name;
  final String? image_url;
  final String? username;
  final String? job_id;
  final String? emp_id;
  final String? emp_profile_id;
  final String? partnerDisplayName;
  final int? companyId;
  final bool? branchId;
  final int? partnerId;
  final String? leaveBalance;
  final String? webBaseUrl;
  final UserCompanies? userCompanies;
  final UserBranches? userBranches;
  final Map<String, Currency>? currencies;
  final bool? showEffect;
  final bool? displaySwitchCompanyMenu;
  final bool? displaySwitchBranchMenu;
  final CacheHashes? cacheHashes;
  final List<dynamic>? allowedBranchIds;
  final List<String>? roles;

  Data({
    this.uid,
    this.isSystem,
    this.isAdmin,
    this.userContext,
    this.db,
    this.serverVersion,
    this.serverVersionInfo,
    this.name,
    this.image_url,
    this.username,
    this.job_id,
    this.emp_id,
    this.emp_profile_id,
    this.partnerDisplayName,
    this.companyId,
    this.branchId,
    this.partnerId,
    this.leaveBalance,
    this.webBaseUrl,
    this.userCompanies,
    this.userBranches,
    this.currencies,
    this.showEffect,
    this.displaySwitchCompanyMenu,
    this.displaySwitchBranchMenu,
    this.cacheHashes,
    this.allowedBranchIds,
    this.roles,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        uid: json["uid"],
        isSystem: json["is_system"],
        isAdmin: json["is_admin"],
        userContext: json["user_context"] == null
            ? null
            : UserContext.fromJson(json["user_context"]),
        db: json["db"],
        serverVersion: json["server_version"],
        serverVersionInfo: json["server_version_info"] == null
            ? []
            : List<dynamic>.from(json["server_version_info"]!.map((x) => x)),
        name: json["name"],
        image_url: json["image_url"].toString(),
        username: json["username"].toString(),
        job_id: json["job_id"].toString(),
        emp_id: json["emp_id"].toString(),
        emp_profile_id: json["emp_profile_id"]?.toString(),
        partnerDisplayName: json["partner_display_name"],
        companyId: json["company_id"],
        branchId: json["branch_id"],
        partnerId: json["partner_id"],
        leaveBalance: json["leave_balance"],
        webBaseUrl: json["web.base.url"],
        userCompanies: json["user_companies"] == null
            ? null
            : UserCompanies.fromJson(json["user_companies"]),
        userBranches: json["user_branches"] == null
            ? null
            : UserBranches.fromJson(json["user_branches"]),
        currencies: json["currencies"] == null
            ? null
            : Map.from(json["currencies"]!).map(
                (k, v) => MapEntry<String, Currency>(k, Currency.fromJson(v))),
        showEffect: json["show_effect"],
        displaySwitchCompanyMenu: json["display_switch_company_menu"],
        displaySwitchBranchMenu: json["display_switch_branch_menu"],
        cacheHashes: json["cache_hashes"] == null
            ? null
            : CacheHashes.fromJson(json["cache_hashes"]),
        allowedBranchIds: json["allowed_branch_ids"] == null
            ? []
            : List<dynamic>.from(json["allowed_branch_ids"]!.map((x) => x)),
        roles: json["roles"] == null
            ? []
            : List<String>.from(json["roles"]!.map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "uid": uid,
        "is_system": isSystem,
        "is_admin": isAdmin,
        "user_context": userContext?.toJson(),
        "db": db,
        "server_version": serverVersion,
        "server_version_info": serverVersionInfo == null
            ? []
            : List<dynamic>.from(serverVersionInfo!.map((x) => x)),
        "name": name,
        "image_url": image_url,
        "username": username,
        "job_id": job_id,
        "emp_id": emp_id,
        "emp_profile_id": emp_profile_id,
        "partner_display_name": partnerDisplayName,
        "company_id": companyId,
        "branch_id": branchId,
        "partner_id": partnerId,
        "leaveBalance": leaveBalance,
        "web.base.url": webBaseUrl,
        "user_companies": userCompanies?.toJson(),
        "user_branches": userBranches?.toJson(),
        "currencies": currencies != null
            ? Map.from(currencies!)
                .map((k, v) => MapEntry<String, dynamic>(k, v.toJson()))
            : null,
        "show_effect": showEffect,
        "display_switch_company_menu": displaySwitchCompanyMenu,
        "display_switch_branch_menu": displaySwitchBranchMenu,
        "cache_hashes": cacheHashes?.toJson(),
        "allowed_branch_ids": allowedBranchIds == null
            ? []
            : List<dynamic>.from(allowedBranchIds!.map((x) => x)),
        "roles": roles == null ? [] : List<dynamic>.from(roles!.map((x) => x)),
      };
}

class CacheHashes {
  final String? loadMenus;
  final String? qweb;
  final String? translations;

  CacheHashes({
    this.loadMenus,
    this.qweb,
    this.translations,
  });

  factory CacheHashes.fromJson(Map<String, dynamic> json) => CacheHashes(
        loadMenus: json["load_menus"],
        qweb: json["qweb"],
        translations: json["translations"],
      );

  Map<String, dynamic> toJson() => {
        "load_menus": loadMenus,
        "qweb": qweb,
        "translations": translations,
      };
}

class Currency {
  final String? symbol;
  final String? position;
  final List<int>? digits;

  Currency({
    this.symbol,
    this.position,
    this.digits,
  });

  factory Currency.fromJson(Map<String, dynamic> json) => Currency(
        symbol: json["symbol"],
        position: json["position"],
        digits: json["digits"] == null
            ? []
            : List<int>.from(json["digits"]!.map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "symbol": symbol,
        "position": position,
        "digits":
            digits == null ? [] : List<dynamic>.from(digits!.map((x) => x)),
      };
}

class UserBranches {
  final List<bool>? currentBranch;
  final List<dynamic>? allowedBranch;

  UserBranches({
    this.currentBranch,
    this.allowedBranch,
  });

  factory UserBranches.fromJson(Map<String, dynamic> json) => UserBranches(
        currentBranch: json["current_branch"] == null
            ? []
            : List<bool>.from(json["current_branch"]!.map((x) => x)),
        allowedBranch: json["allowed_branch"] == null
            ? []
            : List<dynamic>.from(json["allowed_branch"]!.map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "current_branch": currentBranch == null
            ? []
            : List<dynamic>.from(currentBranch!.map((x) => x)),
        "allowed_branch": allowedBranch == null
            ? []
            : List<dynamic>.from(allowedBranch!.map((x) => x)),
      };
}

class UserCompanies {
  final List<dynamic>? currentCompany;
  final List<List<dynamic>>? allowedCompanies;

  UserCompanies({
    this.currentCompany,
    this.allowedCompanies,
  });

  factory UserCompanies.fromJson(Map<String, dynamic> json) => UserCompanies(
        currentCompany: json["current_company"] == null
            ? []
            : List<dynamic>.from(json["current_company"]!.map((x) => x)),
        allowedCompanies: json["allowed_companies"] == null
            ? []
            : List<List<dynamic>>.from(json["allowed_companies"]!
                .map((x) => List<dynamic>.from(x.map((x) => x)))),
      );

  Map<String, dynamic> toJson() => {
        "current_company": currentCompany == null
            ? []
            : List<dynamic>.from(currentCompany!.map((x) => x)),
        "allowed_companies": allowedCompanies == null
            ? []
            : List<dynamic>.from(allowedCompanies!
                .map((x) => List<dynamic>.from(x.map((x) => x)))),
      };
}

class UserContext {
  final int? mapWebsiteId;
  final int? routeMapWebsiteId;
  final int? routeStartPartnerId;
  final String? lang;
  final String? tz;
  final int? uid;

  UserContext({
    this.mapWebsiteId,
    this.routeMapWebsiteId,
    this.routeStartPartnerId,
    this.lang,
    this.tz,
    this.uid,
  });

  factory UserContext.fromJson(Map<String, dynamic> json) => UserContext(
        mapWebsiteId: json["map_website_id"],
        routeMapWebsiteId: json["route_map_website_id"],
        routeStartPartnerId: json["route_start_partner_id"],
        lang: json["lang"],
        tz: json["tz"],
        uid: json["uid"],
      );

  Map<String, dynamic> toJson() => {
        "map_website_id": mapWebsiteId,
        "route_map_website_id": routeMapWebsiteId,
        "route_start_partner_id": routeStartPartnerId,
        "lang": lang,
        "tz": tz,
        "uid": uid,
      };
}
