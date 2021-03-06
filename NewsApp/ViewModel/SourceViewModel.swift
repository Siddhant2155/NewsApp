//
//  SourceViewModel.swift
//  NewsApp
//
//  Created by Siddhant Kumar on 26/07/21.
//

import UIKit

class SourceViewModel {
    
    //MARK:- Properties
    var model: SourceModel!
    /// Used to Reload the TableView Content
    var reloadTableViewCallBack: (() -> Void)?
    /// CallBack contains list of items which need to reload
    var reloadCellsCallBack: (([Source]) -> Void)?
    /// Return the URL of the Source website
    var openBrowserCallBack: ((URL) -> Void)?
    /// Returns the list of available sources
    var getSourceList: [Source] {
        return model.sources
    }
    var sourceIDCallBack: ((String, String) -> Void)?
    private(set) var previousSelectedIndex = -1
    
    var categoryType: Box<Categories?> = Box(nil)
    
    weak var controller: UIViewController?
    init(controller: UIViewController) {
        self.controller = controller
    }
    
    //MARK:- Methods
    /// This function is use to manage the UI toggle
    func selectedIndex(_ indx: Int) {
        if indx == previousSelectedIndex {
            previousSelectedIndex = -1
            reloadCellsCallBack?([model.sources[indx]])
            return
        }
        var tempSourceList = [Source]()
        tempSourceList.append(model.sources[indx])
        if previousSelectedIndex != -1 &&
            previousSelectedIndex != indx {
            tempSourceList.append(model.sources[previousSelectedIndex])
        }
        previousSelectedIndex = indx
        reloadCellsCallBack?(tempSourceList)
    }
    
    /// Returns the valid URL of the source if available else return nil
    func getSelectedNewsLink(of indx: Int) -> URL? {
        return URL(string: model.sources[indx].url)
    }
    
    func setSourceID(of indx: Int) {
        if let lang = Languages.init(rawValue: model.sources[indx].language) {
            UserDefaultsData.language = lang.rawValue
        }
        sourceIDCallBack?(model.sources[indx].id,
                          model.sources[indx].name)
    }
    
    //MARK:- API Call
    func fetchAPI() {
        var params = [String: Any]()
        if let cat = categoryType.value {
            params["category"] = cat.rawValue
        }
        if !UserDefaultsData.country.isEmpty {
            params["country"] = UserDefaultsData.country
        }
        if !UserDefaultsData.language.isEmpty {
            params["language"] = UserDefaultsData.language
        }
        NetworkManager.sharedInstance.fetchData(endPoint: .sources,
                                                params: params,
                                                method: .GET,
                                                responseType: SourceModel.self,
                                                controller: controller
        ) { response in
            switch response {
            case .success(let data):
                self.model = data
                self.reloadTableViewCallBack?()
            case .failure(let error):
                debugPrint(error.showErrorMessage)
            }
        }
    }
}
