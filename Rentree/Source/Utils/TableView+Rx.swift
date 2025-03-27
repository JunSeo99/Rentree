//
//  TableView+Rx.swift
//  Rentree
//
//  Created by jun on 3/27/25.
//
import Foundation
import UIKit
import RxSwift
import RxCocoa
import RxDataSources

final class RxTableViewSectionedReloadDataSourceWithReloadSignal<S: SectionModelType>: RxTableViewSectionedReloadDataSource<S> {
    private let relay = PublishRelay<Void>()
    var dataReloaded : Signal<Void> {
        return relay.asSignal()
    }
    
    override func tableView(_ tableView: UITableView, observedEvent: Event<[S]>) {
        super.tableView(tableView, observedEvent: observedEvent)
        relay.accept(())
    }
}
