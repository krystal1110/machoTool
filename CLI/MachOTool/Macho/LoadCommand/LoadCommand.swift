//
//  LoadCommand.swift
//  MachoTool
//
//  Created by karthrine on 2022/6/24.
//

import Foundation
import MachO


 


let byteSwappedOrder = NXByteOrder(rawValue: 0)

public protocol MachOLoadCommandType {
    
    var name: String { get }
    
}



public struct MachOLoadCommand {
    let data: Data
    let command: UInt32
    let size: Int
    let offset: Int
    let byteSwapped: Bool
    let displayStore:DisplayStore
    
    init(data: Data, offset: Int, byteSwapped: Bool) {
        var loadCommand = data.extract(load_command.self, offset: offset)
        if byteSwapped {
            swap_load_command(&loadCommand, byteSwappedOrder)
        }
        
        
        self.command = loadCommand.cmd
        self.size = Int(loadCommand.cmdsize)
        self.data = data
        self.offset = offset
        self.byteSwapped = byteSwapped
        
        let type =   LoadCommandType(rawValue: command)
        let dataSlice = DataTool.interception(with: data, from: offset, length: Int(loadCommand.cmdsize))
        let displayStore = DisplayStore(dataSlice: dataSlice)
        self.displayStore = displayStore
         
        
        displayStore.insert(item: ExplanationItem(sourceDataRange: DataTool.absoluteRange(with: data, start: 0, 4), model: ExplanationModel(description: "Load Command Type", explanation:type?.name ?? "" )))
        
        displayStore.insert(item: ExplanationItem(sourceDataRange: DataTool.absoluteRange(with: data, start: 4, 8), model: ExplanationModel(description: "Load Command Size", explanation:data.count.hex)))
        
    }
    
    func command(from data: Data, offset: Int, byteSwapped: Bool) -> MachOLoadCommandType? {
        
        let type =   LoadCommandType(rawValue: command)
        switch type {
            
        case .segment, .segment64 :
            return Segment(loadCommand: self)
            
        case .main :
            return LC_Main(loadCommand: self)
            
        case .dyldInfoOnly:
            return LC_DyldInfo(loadCommand: self)
        
        case .symbolTable:
            return LC_SymbolTable(loadCommand: self)
        
        case .sourceVersion:
            return LC_SourceVersion(loadCommand: self)
        
        case .dynamicSymbolTable:
            return LC_DynamicSymbolTable(loadCommand: self)
            
        case .rpath:
            return LC_Rpath(loadCommand: self)
            
        case .uuid:
            return LC_Uuid(loadCommand: self)
        
        case .codeSignature, .segmentSplitInfo, .functionStarts, .dataInCode, .dylibCodeSigDRs,.linkerOption,.linkerOptimizationHint,.dyldExportsTrie,.dyldChainedFixups:
            return LinkeditCommand(loadCommand: self)
            
        case .idDylib, .loadDylib, .loadWeakDylib, .reexportDylib, .lazyLoadDylib, .loadUpwardDylib:
            return LC_Load_Dylib(loadCommand: self)
            
        case .iOSMinVersion, .macOSMinVersion, .tvOSMinVersion, .watchOSMinVersion:
            return LC_MinOSVersion(loadCommand: self)
            
        default:
            return LC_Unknown(loadCommand: self)
        }
    }
}

 
